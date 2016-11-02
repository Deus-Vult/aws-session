# AWS session

A shorthand function I've created for smoothly initiating an AWS MFA session on the command line. It's nothing but a simple .bashrc extension written for my own convenience. It runs on top of the Python AWS client which is described here https://aws.amazon.com/cli/.

## Requirements
Python.

## Usage
### aws-session
<pre>aws-session [token] [-o] [-h|--help]</pre>
Creates a token which will be valid for 3600 seconds.

The <tt>-o</tt> flag will override any previously set token.

### aws-token
<pre>aws-token</pre>
This retrieves any previousy set token. This is automatically called when a shell is opened but needs to be called in old shells to propagate the token.
