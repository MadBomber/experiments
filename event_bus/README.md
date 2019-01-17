# Sin-city Simulation (sinsim.rb) #

Killing several birds with one stone.  The concept behind the
event_bus gem is very simple and looks like its pretty darn
effective at handling simple event-based pub/sub applications.

Also had a dare to do a Sin City Simulation as a man-in-the-loop
implementation of a city-wide syndicate of casinos where the
bank is owned by the syndicate.  Fair warning - **Never Ever take
out a loan with the Syndicate!**


**Table of Contents**

* [Sin\-city Simulation (sinsim\.rb)](#sin-city-simulation-sinsimrb)
    * [Technology Stack](#technology-stack)
    * [Installing Libraries (aka gems)](#installing-libraries-aka-gems)
    * [Running the Application](#running-the-application)
* [TroubleShooting](#troubleshooting)
    * [Program Will Not Run](#program-will-not-run)
        * [Permission Denied](#permission-denied)
        * [Is Ruby Installed?](#is-ruby-installed)
            * [Installing the Ruby Technology Stack](#installing-the-ruby-technology-stack)
                * [Installing the Ruby Version Manager (RVM)](#installing-the-ruby-version-manager-rvm)
                    * [Installing Ruby](#installing-ruby)
                    * [Making a Specific Version of Ruby the Default](#making-a-specific-version-of-ruby-the-default)
    * [Program Crashes](#program-crashes)

  
## Technology Stack ##

This is a Ruby-based command-line interface (CLI)
application.  If you know the Ruby technology stack,
then you know that the common way to setup and
execute this application is to (from its root
directory) in a terminal emulator (aka consol)
do:

    bundler install
    ./sinsim.rb --help

This results in the following output to the terminal:

    Sin Simulation of Gambling at a Casino

    Usage: sinsim.rb [options] ...

    Where:

      Common Options Are:
        -h, --help     show this message
        -v, --verbose  enable verbose mode
        -d, --debug    enable debug mode
        --version      print the version: 0.0.1

      Program Options Are:
        -c, --count    How many Players (count)

    Important:

      You don't need to do this. Go home to your family.

This applications works easily on Linux- and MacOS-based
computers.  If you are using a MicorSloth Windows-based
computer, then there is no technical support (hope) for you.

If you do not know the Ruby technology you are missing out
on one of the best technology stacks for rapid application
development.  Ruby is well suited for R&D and proof-of-concept
applications.

To install Ruby, if its not already installed on your computer
see the section below on how to install Ruby.

## Setup ##

With Ruby installed all you need to do is to ensure that the
libraries (aka gems) required by this application - as identified
in the file "Gemfile" - are installed.  Use the following commands
on the terminal from the root directory of this application:

    gem install bundler
    bundle install

These command will install all of the gems (aka libraries) required
by the application.

## Running the Application ##

To run the application for a single player, do the following from
a console (aka terminal) window:

    ./sinsim.rb -c 1

# TroubleShooting #

A non-extensive guide to fixin' stuff.

## Program Will Not Run ##

The program will not run can be caused by at least two different
factors.  Either the application file "sinsim.rb" does not have
execute permissions set or the ruby programming language is
not installed on your computer.

### Permission Denied ###

If you attempt to execute the "sinsim.rb" application and get
a message like this:

    bash: ./sinsim.rb: Permission denied

it means that the file "sinsim.rb" has not been designated
as an executable file.  On Linux- and MacOS-based computers
do this in a terminal window from the root directory that
contains the "sinsim.rb" application:

    chmod +x sinsim.rb

Doing so will set the executable permission for the application.

An alternative solution is to execute the application like this:

    ruby ./sinsim.rb -c 1

The above command executes Ruby and tells it to run the application
file "./sinsim.rb" with the CLI parameters "-c 1"


### Is Ruby Installed? ###

To find out whether your computer has Ruby installed do the
following from a console (aka terminal emulator):

    ruby --version

On MacOS the output to the terminal will look something
like this:

    ruby 2.6.0p0 (2018-12-25 revision 66547) [x86_64-darwin17]

Any version of Ruby after 2.0.0 will work for this application.

If Ruby is not installed on your computer, the output will
look something like this:

    bash: ruby: command not found

#### Installing the Ruby Technology Stack ####

The basic Ruby technology stack consistes of the Ruby programming
language interpreter, utilities and libraries - called gems.

The first utility to install is the Ruby Version Manager (RVM) which
is used to install and manage different versions of the Ruby technology
stack.

##### Installing the Ruby Version Manager (RVM) #####

Using your web-browser go to this page and follow the instructions:

    https://rvm.io/rvm/install

This will install the Ruby Version Manager (RVM) in you user
account on your computer.  Once RVM is installed then you can
install multiple versions of Ruby..... but you only need one.

###### Installing Ruby ######

With RVM installed correctly, then do this to install the
2.6.0 version of Ruby:

    rvm install 2.6.0

Different versions of the Ruby system can be installed and managed
by the RVM system.  Having different versions of Ruby available is
a best practice during the development of any applications using
Ruby.

For the "sinsim.rb" application only one version of Ruby is necessary.  As
of December 2018 the latest version of Ruby is 2.6.0.

###### Making a Specific Version of Ruby the Default ######

With version 2.6.0 installed, you can do this to make it
your default version:

    rvm use 2.6.0 --default

Verify that Ruby is installed by using this command:

    ruby --version

A good response on a MacOS computer should be something like:

    ruby 2.6.0p0 (2018-12-25 revision 66547) [x86_64-darwin17]

A bad response looks like this:

    bash: ruby: command not found

## Program Crashes ##

In the event tha the program crashes you should be very
happy that its not a real casino.
