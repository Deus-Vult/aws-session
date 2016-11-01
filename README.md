# AWS session

A shorthand function I've created for smoothly initiating an AWS MFA session on the command line. It's nothing but a simple .bashrc extension written for my own convenience. It runs on top of the Python AWS client which is described here https://aws.amazon.com/cli/.

## Requirements
Python.

## Usage
<pre>aws-session [token] [-o] [-h|--help]</pre>
Creates a token which will be valid for 3600 seconds.

The <tt>-o</tt> flag will override any previously set token.
