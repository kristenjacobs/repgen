lappend auto_path . $env(REPGEN_ROOT)
package require RepGenEngine

set g_false 0
set g_true 1

# --------------------------------------------------------------------------- #
# Usage
# --------------------------------------------------------------------------- #
proc Usage {} \
{
    puts "Usage: tclsh ReportGenerator.tcl <input file> <output file> <comment file> <config file>"
    puts "    Tags: <Name>"
    puts "    Tags: <Names>"
    puts "    Tags: <grade>"
    puts "    Tags: <he/she>"
    puts "    Tags: <He/She>"
    puts "    Tags: <his/her>"
    puts "    Tags: <His/Her>"
    puts "    Tags: <him/her>"
    puts "    Tags: <himself/herself>"
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
proc Main {} \
{    
    global argc
    global argv
    global g_true
    global g_false
    
    if {$argc != 4} \
    {
        Usage
        exit 1
    }
 
    set inputFile   [lindex $argv 0]
    set outputFile  [lindex $argv 1]    
    set commentFile [lindex $argv 2]
    set configFile  [lindex $argv 3]
    set errorMessage ""

    if {[ProcessFile $inputFile \
                     $outputFile \
                     $commentFile \
                     $configFile \
                     errorMessage] == $g_false} \
    {
        puts $errorMessage
    }
}

Main

