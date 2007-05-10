
#----------------------------------------------------------------------------
#   Copyright (c) 1999-2001 Jochen Loewer (loewerj@hotmail.com)   
#----------------------------------------------------------------------------
#
#   $Id: xslt.tcl,v 1.12 2004/05/12 02:38:48 rolf Exp $
#
#
#   A simple command line XSLT processor using tDOMs XSLT engine.
#
#
#   The contents of this file are subject to the Mozilla Public License
#   Version 1.1 (the "License"); you may not use this file except in
#   compliance with the License. You may obtain a copy of the License at
#   http://www.mozilla.org/MPL/
#
#   Software distributed under the License is distributed on an "AS IS"
#   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#   License for the specific language governing rights and limitations
#   under the License.
#
#   The Original Code is tDOM.
#
#   The Initial Developer of the Original Code is Jochen Loewer
#   Portions created by Jochen Loewer are Copyright (C) 1998, 1999
#   Jochen Loewer. All Rights Reserved.
#
#   Contributor(s):            
#
#
#
#   written by Rolf Ade
#   August, 2001
#
#----------------------------------------------------------------------------

#foreach { xmlFile xsltFile outputOpt } $argv break



set xsltFile [file join [file dirname [info script]] wsdl-to-api.xsl]
set serverName [ns_queryget s "StockQuoter"]
set outputOpt ""

# This is the callback proc for xslt:message elements. This proc is
# called once every time an xslt:message element is encountered during
# processing the stylesheet. The callback proc simply sends the text
# message to stderr.
proc xsltmsgcmd {msg terminate} {
    ns_log Error "xslt message: $msg"
}

#set ::tDOM::extRefHandlerDebug 1

set xmlInput "[::xml::document::print ::wsdb::definitions::${serverName}::definitions]"

set xmldoc [dom parse  \
                      -externalentitycommand ::tDOM::extRefHandler \
                      -keepEmpties \
		"$xmlInput"]
# \[                     \[::tDOM::xmlReadFile \$xmlFile\] \]

dom setStoreLineColumn 1

set xsltdoc [dom parse -baseurl [::tDOM::baseURL $xsltFile] \
                       -externalentitycommand ::tDOM::extRefHandler \
                       -keepEmpties \
                       [::tDOM::xmlReadFile $xsltFile] ]

dom setStoreLineColumn 0

if {[catch {$xmldoc xslt -xsltmessagecmd xsltmsgcmd $xsltdoc resultDoc} \
         errMsg]} {
    ns_log Error $errMsg
}

if {$outputOpt == ""} {
    set outputOpt [$resultDoc getDefaultOutputMethod]
}

set doctypeDeclaration 0
if {[$resultDoc systemId] != ""} {
    set doctypeDeclaration 1
}

switch $outputOpt {
    asXML -
    xml  {
        if {[$resultDoc indent]} {
            set indent 4
        } else {
            set indent no
        }
        set result [$resultDoc asXML -indent $indent -escapeNonASCII \
                -doctypeDeclaration $doctypeDeclaration]
    }
    asHTML -
    html {
        set result [$resultDoc asHTML -escapeNonASCII -htmlEntities \
                -doctypeDeclaration $doctypeDeclaration]
    }
    asText -
    text {
        set result [$resultDoc asText]
    }
    default {
        ns_log Error "Unknown output method '$outputOpt'!"
    }
}

ns_return 200 text/plain $result