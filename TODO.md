
## TODO

* Documentation:
  * Add YARD documentation for class-level flow constructs
  * Add more documentation for flows
  * BDD-ing a flow
* Make Renderer unicode aware
  * Paginate menu correctly when unicode presence is detected
  * Truncate Renderer#apply correctly
  * When not in unicode mode, iconv down messages to ASCII
* Refactor flow_parser, it's grown too big and unwieldy
* Override input
* Use configuration gem for configuration
* Use syslog for logging
* Fix reloading flows
* Redis sessions:
  * Additional full-stack testing
  * Explore using alternatives to Marshal that preserve symbols versus strings
  * Make all tests pass by defaulting to memory store in tests
* Investigate adding an :input option to switch so that a request block gets passed |input|
* Improve error messages of Renderer Server
* Complete test coverage of Renderer Server using Goliath testing (and Runner, if possible)
* Write performance specs so that we can measure regressions
* Renderer Server improvements
  * Extensive logging throughout
  * Optional full state logging, log everything to YYYYMMDD/HH/MM-MSISDN.log
  * Replay from a full state log
* A i18n framework
* Pagination: support other pagination schemes (e.g. a. b. c. or I. II. III.)
* Pagination: implement an optional previous page.
* Pagination: refine changing prefix and suffix so that the changed prefixes/suffixes results in repagination of the menu
* Pagination: implement previous option on prompts
* Menu: add rewind and previous page options.
* Allow nested organization of messages in YAML files.

## CHANGES

### 20130115 (vishnu@mobme.in)
* A new parameter "accept" can be set to "text/plain" in the server to return only the plain text response instead of JSON.

### 20120717 (binoy@mobme.in)
* Increased input parameter length from 20 to 160 characters
### 20120605 (binoy@mobme.in)
* Flow name from url is now passed into flow objects during instantiation. The solves the switching and flow pool exhaustion issues that occur when flow path is not the same as the flow class
### 20120604 (binoy@mobme.in)
* Bug fix to solve issue which was causing flow pool to get exhausted when flow path and flow class names didn't match
### 20120314 (binoy@mobme.in)
* Minor bug fix in redis helper to enable redis connections to remote servers

### 20120229 (binoy@mobme.in)
* Minor tweak to fit in more text in menu first page
* Previous option in menu can be disabled by setting the previous option text as an empty string

### 20120226 (binoy@mobme.in)
* Added unicode message support

### 20120203 (binoy@mobme.in)
* Added flow pooler to improve renderer performance. Each flow object now has a reference to a unique node object. This may solve concurrency issues.
* Minor performance tuning tweaks

### 20120104 (vishnu@mobme.in)
* Bugfix: Scribe helper is now loaded dynamically

### 20120102 (vishnu@mobme.in)
* Fixing a pretty serious bug in server.rb that resulted in shared state across Fibers. This might solve lots of unexplained behaviour.

### 20120102 (binoy@mobme.in)
* Fixed menu issue occuring when menu input is a very large integer (greater than 2*30)

### 20120101 (vishnu@mobme.in)
* Making ussd-renderer-redux Ruby 1.9.3 ready
* An attempt at better documentation using YARD

### 20111214 (vishnu@mobme.in)
* Adding spec_helpers. Require:

  require 'mobme/infrastructure/ussd\_renderer\_redux/spec\_helpers'

  & you'll have a few methods available to you in your flow spec:
  * stub\_mysql! to stub out MySQL properly.
  * apply\_chain to apply lots of things to a flow at once and return every output
  * state\_for(flow) to find the state (instead of flow.send(:state))

### 20111214 (binoy@mobme.in)
* Fixed prompt pagination issue that was occuring when the message ended with a alphabet.

### 20111116 (binoy@mobme.in)
* Fixed bug in settings helper. YAMLs that are not hashes can be parsed using the settings helper now.
* Fixed issue where sessions were not stored correctly while switching between flows.
* Session data stored in memory store is now 'marshalled', the same way as we do in redis store.
  This means that the flow would error out if we try to store an 'unmarshallable' object in a session whatever the session store may be.
* Hack to remove the default proc that Goliath attaches to the url parameters hash. The default proc makes the flow state 'unmarshallable'

### 20111111 (vishnu@mobme.in)
* Bugfix in menu: now correctly accounts for prefixes or suffixes that vary across pages.

  Note: menu.prefix and menu.suffix blocks must not contain code with sideeffects
  (i.e. these may be executed more times than necessary to generate the menu)
  Use menu.before_page instead to guarantee an invocation before every page render.

### 20111020 (vishnu@mobme.in)
* Message builder has a new syntax for string interpolation. (it's %{variable} instead of %%variable%%)
  _ function remains the same: _([:example, {:user => "Vishnu"}]) but all strings in messages.yaml have to be rewritten!

  Note: the old syntax is DEPRECATED and will be removed in 1.0!
* You can now organize the messages in YAML files hierarchically, see messages/active_record.yaml
  Syntax for the _ function remains the same. Arguments are now split on the underscore character and
  searched in the nested hash built from the YAML.

### 20111019 (vishnu@mobme.in)
* Removed hardcoded version dependencies for em-synchrony and em-http-request

### 20111018 (vishnu@mobme.in)
* Max USSD message length is now configurable in flows.yaml (maximum\_message_length) This is a renderer-wide setting.
* Fixing warnings with specs in the scribe and settings helper.

### 20111018 (sreekanth@mobme.in)
* Settings helper. See examples/settings_flow.rb

### 20111012 (sreekanth@mobme.in)
* Scribe helper. See examples/scribe_flow.rb

### 20111012 (vishnu@mobme.in)
* Additional parameters passed in the server are available as headers[:metadata] in the flow.

### 20111011 (vishnu@mobme.in)
* Fixing a bug whereby sometimes a menu rendered pages of a previous menu. Fixed in menu#reset! by setting pages to nil.
* The simulator does not reset the renderer in between runs. This is to better replicate what happens in production (session_id is incremented instead in between runs)

### 20111004 (vishnu@mobme.in)
* Upgraded to latest eventmachine MASTER (1.0.0.beta.5 from github.com/vishnugopal/eventmachine)

### 20111003 (vishnu@mobme.in)
* Suppress SEVERITIES warning in logger by checking for redefinition.
* BUGFIX: Menu is no longer frozen on switch!
* Menu is now reset completely on switch! (It still retains its state but is frozen on pass! or normal transition to the process block)

### 20110929 (vishnu@mobme.in)
* CHANGED syntax of menu.prefix and menu.suffix to take a block instead. These are executed dynamically
  on every page render to change the prefix and suffix selectively on each page by reading a new headers[:page]
  variable.
* A new menu.before\_page block that can be used to execute code before each page render.

### 20110906 (vishnu@mobme.in)
* switch :back support, including switching back to previous flows

### 20110817 (vishnu@mobme.in)
* Moving notify, switch and pass to the flow parser. As a result, they can be called from the flow too.
* Fixing a bug with rendering multiple pages using a custom more.

### 20110810 (binoy@mobme.in)
* Increased USSD message length from 140 to 160 characters.
* Corrected testcases for the message length change

### 20110806 (vishnu@mobme.in)
* A slight change to flows.yaml to bring flow paths into the flow entry. Note: reloading flows is currently broken because
  of earlier flows.yaml changes.

### 20110804 (vishnu@mobme.in)
* An experimental session store in Redis, needs more tests, but the basic functionality works.
  * Change config/flows.yaml session_store from memory to redis and add sessions and state entries to config/redis.yaml
  * Tested by spawning two independent servers and hitting them with alternate requests
* -a address, -p port, -d for daemonize, -e env, -P pidfile are now handled by the runner and passed on to Goliath
* The logger is available at Colloquy.logger
* To notify consumers, Renderer now constructs a response object which responds to flow state
  * When the flow state is :notify, upstreams should terminate session with the mobile subscriber.
  * The server now responds with a hash of response and flow_state.
  * The simulator now detects :notify and terminates & resets the flow.

### 20110803 (vishnu@mobme.in)
* A first stab at performance testing: see spec/performance (needs much more work).
* Extracting _ (underscore) so that it works in the flow.
* Custom load paths & custom classes for flows: see examples/config/flows.yaml.

### 20110802 (vishnu@mobme.in)
* Graceful error messages from the flow messages YAML (and backup from standard error messages) when something goes wrong.
* Renderer#apply now has a safety wrapper around it by default. This is called by both the server and the interactive tester.
  * Call Renderer#apply! if you want exceptions to be raised.
* Interactive mode has been renamed to simulator and now started with -s.
  * Also adds a "reset" command to the simulator to go back to the beginning of the flow.

### 20110801 (vishnu@mobme.in)
* Pass in -i or --interactive to the ussd-renderer binary to start an interactive mode to test flows.
* A renderer-wide messages.yaml that can be used to set common messages (overridden by flow-specific messages).
* Database access refactored to use Mysql2::EM::Fiber.
* ActiveRecord support for the mysql helper (see examples/active\_record_flow.rb)

### 20110731 (vishnu@mobme.in)
* Move menu_helper to within menu: menu.key(input)
* Menu pagination refactored to return symbols instead of strings.
* Menu.key now takes pages into account.
* Pagination is built into the flow parser and enabled automatically for long menus and prompts
  * Customize the "more" prompt with the message symbol :more

### 20110730 (vishnu@mobme.in)
* Extracting pagination out to be a common element
  * Menu pagination
  * Prompt pagination
  * paginator#total\_pages, paginator#page_available?
* Specs for prompt and menu behavior under pagination

### 20110729 (vishnu@mobme.in)
* A redis helper, use with: redis[:identifier].get/put, etc. from the flow
* MySQL helper changed, now use: mysql[:identifier].query and mysql[:identifier].escape
* Changes to URL Agent means that you can now use: url[:identifier].get for consistency
* The beginnings of robust logging (much more work needed)
* * Menu pagination
  * Correctly paginate menu based on message limits
* Menu has prefix/suffix support

### 20110728 (vishnu@mobme.in)
* Change request hash to headers so that it does not conflict with request block in the node
* A pass instruction to switch from request block to process. When passed, the process block receives the input instead. This is mainly for direct activation use cases where the request block receives an input directly from the USSD for the process block to take care of.
* Message handling, all messages are read from messages/flow_name.yaml
  * Parameterized messages, pass in [:symbol, {:key => "value"}] to either prompt, menu or notify.
    * Works with menu_key
  * A render method for menu
  * An _ (underscore) method for node as an alias to MessageBuilder.to_message

### 20110726 (vishnu@mobme.in)
* mysql helper
  * Databases in mysql.yaml
  * mysql.query(:identifier, query)
* request hash is now available to the node which has :flow\_name, :msisdn, :session_id, :input
* menu_key is now a helper
* The request phase of the node must take |input| which is the initial input
* A URL helper library that tries one URL after another and records downtime
  * URLs in urls.yaml
  * url.call(:url_name, {:parameters})
  * em-synchrony url calls

### 20110724 (vishnu@mobme.in)
* The Renderer Server
  * Loading and running a flow using EM:Synchrony and the Goliath framework
    * Request takes MSISDN, Session ID, Input as parameter
* A generic Renderer Runner to run the Server under Goliath
* A bin/ussd-renderer executable
* Can now switch between nodes with an optional :flow parameter
  * switch :node, :flow => :new_flow.
  * Switching is completely transparent and session and state is still stored in the old flow.

### 20110722 (vishnu@mobme.in)
* The Renderer component (that loads flows and messages) and manages sessions and state is 90%+ complete.
  * method prepare! to be called at start
  * method apply that takes flow\_name, msisdn, session_id and input as parameter and returns response
  * reload messages and flows dynamically

### 20110720 (vishnu@mobme.in)
* A flow parser that uses Ruby where appropriate
  * init, request, process, and notify states for nodes
  * notify function for a USSD termination
  * switch function to switch to a different node
  * Asterisk-like context syntax for nodes
* A simple node implementation with request and process halves
* Exceptions throughout
