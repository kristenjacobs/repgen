package provide RepGenEngine 1.0

set g_false 0
set g_true 1

# --------------------------------------------------------------------------- #
# LogFile
# --------------------------------------------------------------------------- #
proc LogFile {logString} \
{
    # Opens the 'verbose' logfile...
    set logFp [open "Log.txt" a]
    puts $logFp $logString
    close $logFp
}

# --------------------------------------------------------------------------- #
# ReadCommentFile
# --------------------------------------------------------------------------- #
proc ReadCommentFile {commentFp} \
{
    set commentList {}
    set found 0

    while {[gets $commentFp line] >= 0} \
    {
        # Ignore empty lines...
        if {$line == ""} { continue }

        set line [string trim $line]

        # Are we staring a new comment?
        if {[string match +=* $line] == 1} \
        {
            if {$found == 1} \
            {
                # Stores the value from the previous key.
                lappend commentList $value
            }

            set key [string range $line 2 end]
            lappend commentList $key
            set found 1
            set value ""
        } \
        elseif {$found == 1} \
        {
            append value "$line "
        } 
    }

    if {$found == 1} \
    {
        # Stores the value from the previous key.
        lappend commentList $value
    }                                                               
   
    return $commentList
}


# --------------------------------------------------------------------------- #
# ReadConfigFile
# --------------------------------------------------------------------------- #
proc ReadConfigFile {configFp} \
{
    set configList {}

    while {[gets $configFp line] >= 0} \
    {
        # Removes the comments/comment lines...
        set lineList [split $line #]
        set line [string trim [lindex $lineList 0]]

        # Ignore empty lines...
        if {$line == ""} { continue }

        set lineList [split $line =]
        set key   [lindex $lineList 0]
        set value [lindex $lineList 1]

        if {($key == "VERBOSE") || \
            ($key == "NAME_INDEX") || \
            ($key == "GENDER_INDEX") || \
            ($key == "GRADE_INDEX") || \
            ($key == "SCORE_COLUMNS") || \
            ($key == "OUTPUT_COLUMNS") || \
            ($key == "IGNORE_LINES") || \
            ($key == "MALE_TAG") || \
            ($key == "FEMALE_TAG")} \
        {
           lappend configList $key
           lappend configList $value 
        }
    }                                                               
   
    return $configList
}

# --------------------------------------------------------------------------- #
# GetReport
# --------------------------------------------------------------------------- #
proc GetReport {configArray \
                commentArray \
                score \
                name \
                gender \
                grade \
                errorString} \
{
    upvar $errorString error
    upvar $configArray config
    upvar $commentArray comment

    # Checks to see if this score exists in the comment array
    if {[array names comment $score] == ""} \
    {
        set error "'$score' is not a valid score (i.e. could not find corresponding comment)"
        return ""
    }
        
    set report $comment($score)

    regsub -all "<Name>" $report $name report
    
    # Need to check the last letter of the name to see
    # if we need to add an appostophe...
    set lastLetter [lindex [split $name {}] end]
    if {$lastLetter == "s"} \
    {
        set names "${name}'s"
    } \
    else \
    {
        set names "${name}s"
    }
    regsub -all "<Names>" $report $names report

    if {$gender == $config(MALE_TAG)} \
    {
        regsub -all "<he/she>"          $report "he"      report
        regsub -all "<He/She>"          $report "He"      report
        regsub -all "<his/her>"         $report "his"     report
        regsub -all "<His/Her>"         $report "His"     report
        regsub -all "<him/her>"         $report "him"     report
        regsub -all "<himself/herself>" $report "himself" report
    } \
    elseif {$gender == $config(FEMALE_TAG)} \
    {
        regsub -all "<he/she>"          $report "she"     report
        regsub -all "<He/She>"          $report "She"     report
        regsub -all "<his/her>"         $report "her"     report
        regsub -all "<His/Her>"         $report "Her"     report
        regsub -all "<him/her>"         $report "her"     report
        regsub -all "<himself/herself>" $report "herself" report
    } \
    else \
    {
        set error "Error: Unrecognised gender: $gender"
        return ""
    }
 
    # Now handle the grade tag...
    regsub -all "<grade>" $report $grade report
 
    # Now check for any <tags> not replaced.....
    if {[regexp "<.*>" $report matchTag] == 1} \
    {
        set error "Error: Unrecognised tag $matchTag in comment $score"
        return ""
    }
    # Now check for any unmatched '<|>' tags...
    if {[regexp "<\[A-Za-z\]*" $report matchTag] == 1} \
    {
        set error "Error: No closing tag: $matchTag in comment $score"
        return ""
    }
    if {[regexp "\[A-Za-z\]*>" $report matchTag] == 1} \
    {
        set error "Error: No opening tag: $matchTag in comment $score"
        return ""
    }
 
    return $report
}

# --------------------------------------------------------------------------- #
# PrintCommentArray
# --------------------------------------------------------------------------- #
proc PrintCommentArray {commentArray} \
{
    upvar $commentArray comment

    LogFile "------------------------------------------------------------"
    LogFile "Comments"
    LogFile "------------------------------------------------------------"
    
    set searchId [array startsearch comment]

    while {[array anymore comment $searchId]} \
    {
        set key [array nextelement comment $searchId]
        set value $comment($key)

        LogFile "+=$key"
        LogFile "$value"
    }
    array donesearch comment $searchId
}

# --------------------------------------------------------------------------- #
# PrintConfigArray
# --------------------------------------------------------------------------- #
proc PrintConfigArray {configArray} \
{
    upvar $configArray config

    LogFile "------------------------------------------------------------"
    LogFile "Configuration"
    LogFile "------------------------------------------------------------"
    LogFile "VERBOSE        = $config(VERBOSE)"
    LogFile "NAME_INDEX     = $config(NAME_INDEX)"
    LogFile "GRADE_INDEX    = $config(GRADE_INDEX)"
    LogFile "GENDER_INDEX   = $config(GENDER_INDEX)"
    LogFile "SCORE_COLUMNS  = $config(SCORE_COLUMNS)"
    LogFile "OUTPUT_COLUMNS = $config(OUTPUT_COLUMNS)"
    LogFile "IGNORE_LINES   = $config(IGNORE_LINES)"
    LogFile "MALE_TAG       = $config(MALE_TAG)"
    LogFile "FEMALE_TAG     = $config(FEMALE_TAG)"
    LogFile "------------------------------------------------------------"
}

# --------------------------------------------------------------------------- #
# ProcessFile
# --------------------------------------------------------------------------- #
proc ProcessFile {inputFile \
                  outputFile
                  commentFile \
                  configFile \
                  errorString} \
{
    global g_false
    global g_true

    # Removes any previous log file....
    file delete -force Log.txt
    
    # Passes the error string back to the calling proceedure...
    upvar $errorString error

    # Open the input database....
    if {[catch {open $inputFile r} inFp] != 0}\
    {
        set error "Error: Could not open the input file: $inputFile"
        return $g_false
    }

    # Open the output database...
    if {[catch {open $outputFile w} outFp] != 0}\
    {
        set error "Error: Could not open the output file: $outputFile"
        return $g_false
    }

    # Process the config file...
    if {[catch {open $configFile r} configFp] != 0} \
    {
        set error "Error: Could not open the config file: $configFile"
        return $g_false
    }
    array set config [ReadConfigFile $configFp]
    close $configFp
    if {$config(VERBOSE)} { PrintConfigArray config } 
    
    # Process the comments file...
    if {[catch {open $commentFile r} commentFp] != 0}\
    {
        set error "Error: Could not open the comment file: $commentFile"
        return $g_false
    }
    array set comment [ReadCommentFile $commentFp]
    close $commentFp
    if {$config(VERBOSE)} { PrintCommentArray comment } 
          
    set lineNum -1

    # Go through each entry in the database,
    # and add the text...
    while {[gets $inFp line] >= 0} \
    {
        incr lineNum
        set lineList [split $line ,]
       
        if {$config(VERBOSE)} { LogFile "------------------------------------------------------------" }
        
        # Do we need to ignore this line?
        set ignore 0 
        foreach ignoreLine $config(IGNORE_LINES) \
        {
            if {$config(VERBOSE)} { LogFile "lineNum: $lineNum, ignoreLine: $ignoreLine, $line" }

            if {$lineNum == $ignoreLine} \
            {
                if {$config(VERBOSE)} { LogFile "IGNORED!" }
           
                # This line is to be ignored, so 
                # output this line to the file without change.... 
                foreach i $lineList \
                {
                    puts -nonewline $outFp "$i;"
                }
                puts $outFp ""
                set ignore 1
                break
            }
        }
        if {$ignore} { continue }

        set name   [string trim [lindex $lineList $config(NAME_INDEX)]]
        set gender [string trim [lindex $lineList $config(GENDER_INDEX)]]
        set grade  [string trim [lindex $lineList $config(GRADE_INDEX)]]
         
        # Initialise the report array.
        if {[array exists report]} \
        {
            unset report
            array set report {}
        }
    
        if {$config(VERBOSE)} \
        {
            LogFile "name: $name"
            LogFile "gender: $gender"
            LogFile "grade: $grade"
        }

        # Gets the report texts...  
        foreach scoreIndex $config(SCORE_COLUMNS) \
        {
            set score [string trim [lindex $lineList $scoreIndex]]
            
            if {$config(VERBOSE)} { LogFile "scoreIndex: $scoreIndex, score: $score" }

            if {$score != ""} \
            {
                set errorMessage ""
                set report($scoreIndex) [GetReport config \
                                                   comment \
                                                   $score \
                                                   $name \
                                                   $gender \
                                                   $grade \
                                                   errorMessage]

                # Checks for errors in the above call...
                if {$errorMessage != ""} \
                { 
                    set error $errorMessage
                    return $g_false 
                }

                if {$config(VERBOSE)} { LogFile "$report($scoreIndex)" }
            }
        } 
 
        # Output to the file....
        foreach outIndex $config(OUTPUT_COLUMNS) \
        {
            if {[info exists report($outIndex)]} \
            {
                puts -nonewline $outFp "$report($outIndex);"
            } \
            else \
            {
                puts -nonewline $outFp "[lindex $lineList $outIndex];"
            }
        }   
        puts $outFp ""  
    }

    close $inFp    
    close $outFp   
 
    return $g_true
}

