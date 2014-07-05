# encoding: UTF-8
require_relative '../spec_helper'
require 'active_support/core_ext/string'

describe Colloquy::Menu do
  MENU_MESSAGES = {
      a: 'Apple', b: 'Boy', c: 'Cat',
      d: 'Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.',
      e: 'Elephant', f: 'Fool', g: 'God',
      h: 'Hibiscus is a super plant! It is very red and blue and all.',
      i: 'Idiot', j: 'Joker',
      k: 'King Kong is super comedy',
      l: 'Love', m: 'Mother', n: 'Neat', o: 'Open',
      p: 'Princess', q: 'Queen', r: 'Reindeer', s: 'Socrates',
      t: 'Talktime', u: 'Umbrella', v: 'Victory', w: 'Wonderful',
      x: 'Xena', y: 'YoYo', z: 'Zero'
  }
  
  UNICODE_MENU = {
      a: 'ഒന്ന്',
      b: 'രണ്ട് രണ്ട്',
      c: 'മൂന്ന് മൂന്ന് മൂന്ന്',
      d: 'നാലു നാലു നാലു നാലു',
      e: 'അഞ്ച് അഞ്ച് അഞ്ച്',
      f: 'ആറ് ആറ് ആറ്',
      g: 'ഏഴ് ഏഴ്',
      h: 'എട്ട്'
  }

  FOOTBALL_MENU = {
      a: 'Arsenal - Robin Van Persie', b: 'Barcelona FC - Lionel Messi', c: 'Chelsea FC- Frank Lampard',
      d: 'Manchester United - Wayne Rooney', e: 'Real Madrid - Cristiano Ronaldo dos Santos Aveiro'
  }
  
  before(:each) do
    Colloquy.maximum_message_length = 160
  end
  
  describe '#render' do
    let(:flow) do
      double('flow', messages: MENU_MESSAGES.merge(more: 'More', previous: 'Previous'), headers: {})
    end
    
    let(:menu) do 
      Colloquy::Menu.new(flow: flow)
    end
    
    it 'should render a single-item menu' do
      menu.push(:a)

      expect(menu.render).to eq('1. Apple')
    end
    
    it 'should render a simple menu' do
      menu.push(:a, :b, :c)

      expect(menu.render).to eq("1. Apple\n2. Boy\n3. Cat")
    end
    
    it 'should accept a prefix and a suffix' do
      menu.prefix { 'Chennai ROTN Wonderkid!' }
      menu.suffix { 'Powered by MobME' }
      menu.push(:a, :b)

      expect(menu.render).to eq("Chennai ROTN Wonderkid!\n1. Apple\n2. Boy\nPowered by MobME")
    end
  end
      
  context 'with larger menus' do
    let(:flow) do
      double('flow', messages: MENU_MESSAGES.merge(more: 'More', previous: 'Previous'), headers: {})
    end
    
    let(:menu) do 
      Colloquy::Menu.new(flow: flow)
    end
        
    it 'should render the first page' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.render).to include 'More'
      expect(menu.render).to include '1. Apple'
    end

    it 'should render the first page without previous' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.render).not_to include 'Previous'
    end
    
    it 'should render subsequent pages' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.render(2)).to eq("1. Fool\n2. God\n3. Hibiscus is a super plant! It is very red and blue and all.\n4. Idiot\n5. Joker\n6. King Kong is super comedy\n7. Love\n8. Previous\n9. More")
    end

    it 'should render subsequent pages with previous' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.render(2)).to include 'Previous'
    end
    
    it 'should render a page which is set using current_page=' do
      menu.push(*MENU_MESSAGES.keys)
      menu.page = 2

      expect(menu.render(2)).to eq("1. Fool\n2. God\n3. Hibiscus is a super plant! It is very red and blue and all.\n4. Idiot\n5. Joker\n6. King Kong is super comedy\n7. Love\n8. Previous\n9. More")
    end

    it 'should render the last page without More' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.render(4)).not_to include 'More'
      expect(menu.render(4)).to eq("1. Zero\n2. Previous")
    end

    it 'should render all pages with all menu options' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.render).to eq("1. Apple\n2. Boy\n3. Cat\n4. Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.\n5. Elephant\n6. More")
      expect(menu.render(2)).to eq("1. Fool\n2. God\n3. Hibiscus is a super plant! It is very red and blue and all.\n4. Idiot\n5. Joker\n6. King Kong is super comedy\n7. Love\n8. Previous\n9. More")
      expect(menu.render(3)).to eq("1. Mother\n2. Neat\n3. Open\n4. Princess\n5. Queen\n6. Reindeer\n7. Socrates\n8. Talktime\n9. Umbrella\n10. Victory\n11. Wonderful\n12. Xena\n13. YoYo\n14. Previous\n15. More")
      expect(menu.render(4)).to eq("1. Zero\n2. Previous")
    end
    
    it 'should render pages which are less than or equal to standard message length' do
      menu.push(*MENU_MESSAGES.keys)
      length = Colloquy.maximum_message_length
      (1..3).each do |page|
        expect(menu.render(page).length).to be <= length
      end
    end
    
    it 'should paginate accounting for prefixes and suffixes' do
      menu.push(*MENU_MESSAGES.keys)
      menu.prefix { 'Vishnu Gopal' }
      menu.suffix { 'Powered by MobME, a wonderful place to work!' }

      expect(menu.render(7)).to eq("Vishnu Gopal\n1. Xena\n2. YoYo\n3. Zero\n4. Previous\nPowered by MobME, a wonderful place to work!")
    end
    
    it 'should report total pages' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.total_pages).to eq(4)
    end
    
    it 'should report which pages are available and not' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.page_available?(2)).to be true
      expect(menu.page_available?(0)).to be false
      expect(menu.page_available?(-1)).to be false
      expect(menu.page_available?(6)).to be false
    end
    
    it 'should handle a custom more' do
      flow_with_custom_more = double('flow', messages: MENU_MESSAGES.merge(more: 'Go to the next page'), headers: {})
      menu = Colloquy::Menu.new(flow: flow_with_custom_more)
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.send(:render_more)).to eq('Go to the next page')
      expect(menu.render(2)).to include 'Go to the next page'

      length = Colloquy.maximum_message_length

      (1..menu.total_pages).each do |page|
       expect(menu.render(page).length).to be <= length
      end
    end

    it 'should paginate correctly when the menu maximum length is crossed by the last element on the menu' do
      football_flow = double('flow', messages: FOOTBALL_MENU.merge(more: 'More', previous: 'Previous'), headers: {})
      menu = Colloquy::Menu.new(flow: football_flow)
      menu.push(*FOOTBALL_MENU.keys)
      
      expect(menu.render).to eq("1. Arsenal - Robin Van Persie\n2. Barcelona FC - Lionel Messi\n3. Chelsea FC- Frank Lampard\n4. Manchester United - Wayne Rooney\n5. More")
      expect(menu.render(2)).to eq("1. Real Madrid - Cristiano Ronaldo dos Santos Aveiro\n2. Previous")
    end
  end

  context 'when menu items have unicode characters in them' do
    let(:flow) do
      double('flow', messages: UNICODE_MENU.merge(more: 'More', previous: 'Previous'), headers: {})
    end

    let(:menu) do 
      Colloquy::Menu.new(flow: flow)
    end

    it 'should render a simple unicode menu' do
      menu.prefix { 'മലയാളം മെനു' }
      menu.suffix { 'കിടു തന്നെ' }
      menu.push(:a, :b)

      expect(menu.render).to eq("മലയാളം മെനു\n1. ഒന്ന്\n2. രണ്ട് രണ്ട്\nകിടു തന്നെ")
    end

    it 'should render all pages of a large unicode menu' do
      menu.push(*UNICODE_MENU.keys)

      expect(menu.render).to eq("1. ഒന്ന്\n2. രണ്ട് രണ്ട്\n3. മൂന്ന് മൂന്ന് മൂന്ന്\n4. More")
      expect(menu.render(2)).to eq("1. നാലു നാലു നാലു നാലു\n2. അഞ്ച് അഞ്ച് അഞ്ച്\n3. Previous\n4. More")
      expect(menu.render(3)).to eq("1. ആറ് ആറ് ആറ്\n2. ഏഴ് ഏഴ്\n3. എട്ട്\n4. Previous")
    end
  end

  context 'when the previous message is an empty string' do
    let(:flow) do
      double('flow', messages: MENU_MESSAGES.merge(more: 'More', previous: ''), headers: {})
    end

    let(:menu) do 
      Colloquy::Menu.new(flow: flow)
    end

    it 'should render pages without the previous option' do
      menu.push(*MENU_MESSAGES.keys)

      expect(menu.render).to eq("1. Apple\n2. Boy\n3. Cat\n4. Created by Shigeru Miyamoto, Donkey-Kong is a series of video games that features the adventures of a large ape.\n5. Elephant\n6. More")
      expect(menu.render(2)).to eq("1. Fool\n2. God\n3. Hibiscus is a super plant! It is very red and blue and all.\n4. Idiot\n5. Joker\n6. King Kong is super comedy\n7. Love\n8. Mother\n9. More")
      expect(menu.render(3)).to eq("1. Mother\n2. Neat\n3. Open\n4. Princess\n5. Queen\n6. Reindeer\n7. Socrates\n8. Talktime\n9. Umbrella\n10. Victory\n11. Wonderful\n12. Xena\n13. YoYo\n14. Zero")
    end
  end
  
  context 'identifying correct key from a menu' do
    let(:calculator) do 
      class CalculatorInsideMenu
        include Colloquy::FlowParser
      end.new
    end

    it 'correctly identifies menu.key from a string of menus' do
      calculator.node_add(:index) do 
        request {
          menu << 'Add' << 'Delete'
        }

        process { |input|
          case menu.key(input)
          when 'Add'
            notify 'Inside Add'
          when 'Delete'
            notify 'Inside Delete'
          end
        }
      end

      calculator.apply
      expect(calculator.apply(1)).to eq 'Inside Add'

      calculator.reset!

      calculator.apply
      expect(calculator.apply(2)).to eq 'Inside Delete'
    end

    it 'correctly identifies menu.key from a menu with symbols' do
      calculator.node_add(:index) do 
        request {
          menu << :add << :delete
        }

        process { |input|
          case menu.key(input)
          when :add
            notify 'Inside Add'
          when :delete
            notify 'Inside Delete'
          end
        }
      end

      calculator.apply
      expect(calculator.apply(1)).to eq 'Inside Add'

      calculator.reset!

      calculator.apply
      expect(calculator.apply(2)).to eq 'Inside Delete'
    end

    it 'correctly identifies menu.key from a menu with a message key with parameters' do
      calculator.node_add(:index) do 
        request {
          menu << [:add, { branding: 'Crosshair' }] << [:delete, { branding: 'Crosshair' }]
        }

        process { |input|
          case menu.key(input)
          when :add
            notify 'Inside Add'
          when :delete
            notify 'Inside Delete'
          end
        }
      end

      calculator.apply
      expect(calculator.apply(1)).to eq 'Inside Add'

      calculator.reset!

      calculator.apply
      expect(calculator.apply(2)).to eq 'Inside Delete'
    end
    
    it 'correctly identifies menu.key from a paginated menu' do
      calculator.node_add(:index) do 
        request {
          menu << :add << :delete << :elephant << :fox << :god << :hitler << :idiot << :joker << :king << :love << :mate << :nether << :open << :poker << :queen << :rise << :shake << :token << :umbrella
        }

        process { |input|
          notify menu.key(input)
        }
      end

      calculator.apply
      expect(calculator.apply(1)).to eq 'add'
      
      calculator.reset!
      calculator.apply
      calculator.apply(18)
      expect(calculator.apply(2)).to eq 'umbrella'
    end
    
    it 'does not render the last option when nothing is given for input' do
      calculator.node_add(:index) do 
        request {
          menu << [:add, { branding: 'Crosshair' }] << [:delete, { branding: 'Crosshair' }]
        }

        process { |input|
          case menu.key(input)
          when :add
            notify 'Inside Add'
          when :delete
            notify 'Inside Delete'
          else
            notify 'Something else'
          end
        }
      end

      calculator.apply
      output = calculator.apply

      expect(output).not_to eq 'Inside Delete'
      expect(output).to eq 'Something else'
    end
    
    it 'can re-render the menu when requested' do
      calculator.node_add(:index) do 
        request {
          menu << :add << :delete
        }

        process { |input|
          switch :index
        }
      end

      calculator.apply
      expect(calculator.apply(2)).to eq "1. add\n2. delete"
    end
    
    it 'rewinds to the first page when re-renderered' do
      calculator.node_add(:index) do 
        request {
          menu << :add << :delete << :elephant << :fox << :god << :hitler << :idiot << :joker << :king << :love << :mate << :nether << :open << :poker << :queen << :rise << :shake << :token << :umbrella
        }

        process { |input|
          switch :index
        }
      end

      expect(calculator.apply).to eq("1. add\n2. delete\n3. elephant\n4. fox\n5. god\n6. hitler\n7. idiot\n8. joker\n9. king\n10. love\n11. mate\n12. nether\n13. open\n14. poker\n15. queen\n16. rise\n17. shake\n18. more")

      calculator.apply(18)
      expect(calculator.apply(3)).to eq("1. add\n2. delete\n3. elephant\n4. fox\n5. god\n6. hitler\n7. idiot\n8. joker\n9. king\n10. love\n11. mate\n12. nether\n13. open\n14. poker\n15. queen\n16. rise\n17. shake\n18. more")
    end
    
    it 'respects the maximum message length' do
      allow(Colloquy).to receive(:maximum_message_length).and_return(140)
      calculator.node_add(:index) do 
        request {
          menu << :add << :delete << :elephant << :fox << :god << :hitler << :idiot << :joker << :king << :love << :mate << :nether << :open << :poker << :queen << :rise << :shake << :token << :umbrella
        }

        process { |input|
          switch :index
        }
      end
      
      expect(calculator.apply).to eq("1. add\n2. delete\n3. elephant\n4. fox\n5. god\n6. hitler\n7. idiot\n8. joker\n9. king\n10. love\n11. mate\n12. nether\n13. open\n14. poker\n15. queen\n16. more")
    end

    it 'should return false if the menu input is greater than the current page menu item count' do
      calculator.node_add(:index) do 
        request {
          menu << :add << :delete << :elephant << :fox << :god << :hitler << :idiot << :joker << :king << :love << :mate << :nether << :open << :poker << :queen << :rise << :shake << :token << :umbrella
        }

        process { |input|
          if menu.key(input)
            notify menu.key(input)
          else
            notify 'Input out of range'
          end
        }
      end

      calculator.apply
      expect(calculator.apply(19)).to eq 'Input out of range'
      
      calculator.reset!
      calculator.apply
      calculator.apply(18)
      expect(calculator.apply(5)).to eq 'Input out of range'

      calculator.reset!
      calculator.apply
      expect(calculator.apply(9999999999999999999999)).to eq 'Input out of range'
    end

  end
end
