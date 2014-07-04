# Colloquy

## Overview

Colloquy is a library to build [USSD](http://en.wikipedia.org/wiki/Unstructured_Supplementary_Service_Data) applications in Ruby. It's a high-level full stack framework and addresses all common USSD needs: examples including building and managing a menu in USSD, accessing services over HTTP or even writing a hangman game.

## Philosophy

* Ruby is more often than not the best DSL.
* Stay as close to the USSD spec as possible. Use the same terminology when possible.
* Be fast.
* Make BDD or TDD easy to do.
* Address real world needs, so handle slow backends gracefully and provide helpers for all common tasks.

## Prerequisites

You'll need to have a basic understanding of how [USSD](http://en.wikipedia.org/wiki/Unstructured_Supplementary_Service_Data)  applications work. The most common example of a USSD application is how folks check balance on a mobile phone: on Vodafone India for example, this is by dialing _*141#_. This special "phone number" is a USSD code.

## Installing for Core Development

**Note:** you only need to do this if you intend to tweak the redux code itself. If you just want to develop USSD applications, see Installation for Flow Developers.

First install rvm and ruby > 1.9.3.

Then do:

    $ bundle install

## Writing Flows

### Basic Terms

* _Flow_: a collection of a set of USSD responses that are sent to a MS in response to a USSD query. Often, a USSD _flow_ is the
  same as as USSD _Application_
* _Mobile Subscriber_ (or just _MS_): This is a terminal device (usually a mobile phone) used to send and receive mobile messages.
* _Application_: A USSD Application which is most often just one flow, but can be a collection of flows working together to provide a service to a _mobile subscriber_.

### Introduction

While programming using ussd-renderer-redux, Flows are collections of Nodes. Each Node has two blocks: a Request block that sends a USSD request to an MS and a Process block where the response received from an MS is analysed. The initial node is by convention named _index_.

A typical USSD request-response would follow this path:

    Index Node -> Request -> Prompt for Input from MS -> Process -> Another Node ... (and so on)

Thus Flows traverse from Node to Node, and at each step, uses a Prompt to ask the MS for more Input. Flows end when Notify is used to tell the MS that the USSD Session is now over.

### Writing your first flow

See Installation for Flow Developers first.

Flows are just Ruby classes with a module {Colloquy::FlowParser} mixed in. This module in addition to providing the class with some special statements (like _prompt_ and _notify_) also has some meta-programming magic to make writing flows simpler. If you've ever worked with [Adhearsion dialplans](http://adhearsion.com/examples), this will look similar, but it has some quirks of its own.

Before we start, if you'd like to just jump in, there are several examples available in the examples/ directory if you've cloned the Git repository. See {CalculatorFlow} for a jumpstart.

This is a simple flow:
    
    class HelloWorldFlow
      include Colloquy::FlowParser

      index {
        request {
          prompt "Enter your name: "
        }

        process { |input|
          notify "Hello #{input}!"
        }
      }
    end
    
We begin a normal Ruby class definition, include the flow parser module and start writing the _index_ node by writing index and then opening up a curly braces pair. Nested within the index node, you have two blocks: a request block and a process block.

Remember: the request block always asks for input, and the process block always analyses it. This is a convention that you should stick to throughout Redux flows to ensure readable and idiomatic flows.

To run this flow: 

* Save this as lib/hello\_world\_flow.rb
* Add a line to app/config/flows.yaml under _active_:
  
        - hello_world

* Run this in the simulator:

        $ bundle exec ussd-renderer -s app
        Please enter flow name:
        hello_world
        Please enter msisdn: 
        111
        Please enter session_id: 
        1212
        Initial input (for direct flow): 
        > (press Enter)
        Hello World
        ---Flow complete---
        --Going back to beginning of flow--
        Initial input (for direct flow):
        > quit
        Bye!

  Note: quit exits the simulator.

Congrats, you've written and tested your first flow!

### Writing More Complex Flows

USSD Renderer Redux comes with a lot of helper methods that allow for complex USSD applications to be built. Here are some of its features:

* A Menu is one of the most common elements of an interactive USSD flow. This is what a simple menu looks like:

        index {
          request {
            menu << :add << :subtract
          }

          process { |input|
            notify "You selected #{menu.key(input)}"
          }
        }

  which renders to:

      1. Add
      2. Subtract
      Enter your choice:

  Redux comes built in with a very capable menu that can paginate larger menus automatically, provide different prefixes and suffixes on each page, and automatically map user input to descriptive menu keys.

* A helper method called _url_ that is a wrapper around Colloquy::URLAgent. This is a robust library that calls HTTP URLs in an evented fashion and supports fallback URLs for a single service.

* Many other evented helpers, _redis_, _mysql_ to access these servers and a _settings_ helper to read in configuration.

### More Example Flows

Checkout the code and take a look at the examples/ directory. There are a lot more flows in there:

  * active\_record\_flow: Connects to ActiveRecord. Configuration in config/mysql.yaml
  * art\_of\_war\_flow: Run this flow to see how menu pagination works seamlessly.
  * calculator\_flow.rb: A simple calculator in USSD.
  * crossover\_flow.rb: This describes the syntax for switching between flows.
  * database\_flow.rb: The raw evented mysql helper (without ActiveRecord). Configuration in config/mysql.yaml
  * hangman\_flow.rb: A simple hangman game in USSD.
  * metadata_flow.rb: Describes how to access request metadata (for e.g. parameters like mobile number location passed in from the stub) within the flow.
  * pagination\_flow: A menu with a long prefix.
  * pass\_flow: Describes the _pass_ special statement that is used mostly in direct entry flows.
  * settings\_flow: for the _settings_ helper. Configuration in config/settings.yaml
  * url\_flow: for the url helper. Configuration in config/urls.yaml

## Deployment Concepts

A USSD application running under the renderer typically has these components running end-to-end from mobile subscriber to the flow running inside the renderer:

    Mobile Subscriber <--> Mobile Operator <--> USSD Gateway <--> Gateway Middleware (or Stub) <--> USSD Renderer <--> Flow

You can see then that the Renderer is just a small piece of the pie. To deploy USSD applications, you'll have to get connectivity to a USSD gateway that can send and receive USSD messages to and from mobile subscribers. This usually involves talking to a mobile network operator in your country to see if they can provide you access.

Depending on what kind of platform your mobile operator's USSD gateway is developed in, you will also have to write some sort of gateway middleware (some folks call this a 'stub') to connect the Renderer to the operator's USSD gateway. USSD gateways are usually proprietary solutions and they differ from gateway to gateway. As of now, the Renderer does not come with any default stubs, but these should be simple to write because the Renderer is flexible enough to speak any protocol and language. In the ideal scenario, you'll just use a stub that can send and process HTTP requests served by the Renderer Server.

What if you do not have connectivity to a gateway? Renderer provides a simulator that can simulate a mobile subscriber and allow you to run your flow.
