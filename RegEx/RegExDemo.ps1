$string = 'The quick brown fox jumped over the lazy dog'

# Note regular -match in Powershell is case insensitive so using cmatch to make case sensitive

$string -cmatch 'fix'
$string -cmatch 'fox'

# . is a wild card for a single character (except a new line)
$string -cmatch 'f.x'
'The quick brown foox jumped over the lazy dog' -cmatch 'f.x' #nope, only one character per .

# [ ] is a character group and can match any ONE of the characters
$string -cmatch 'f[io]x'
'can we fix it' -cmatch 'f[io]x'

# Use ( ) for group and | for or
'John Savill' -cmatch 'Jo(n|hn)'
'Jon Savill' -cmatch 'Jo(n|hn)'
'Joh Savill' -cmatch 'Jo(n|hn)'
'Joh Savill' -cmatch 'Jo[n|hn]' #because with [] its just one of the characters, i.e.g n or h or n!

# ^ matches NOT in the group
$string -cmatch 'f[^xyz]x'

# can use a range in this case any lower case character
$string -cmatch 'f[a-z]x'

# or multiple
$string -cmatch 'f[a-z][a-z]'

# can or with | multiple character groups
'fOx' -cmatch 'f[a-z]x'
'fOx' -cmatch 'f[a-z]|[A-Z]x'
'f0x' -cmatch 'f[a-z]|[A-Z]|[0-9]x'

# this also works as its multiple ranges within a single character group
'fix' -cmatch 'f[a-zA-Z0-9]x'

# \w for any word character, i.e. [a-zA-Z0-9_] includes underscore
'f0x' -cmatch 'f\wx'
$string -cmatch 'f\wx'

# ^ (caret) means the start of the string. A type of anchor
$string -cmatch '^fox'
$string -cmatch '^The'

# $ means the end of the string
$string -cmatch 'fox$'
$string -cmatch 'dog$'

# I may only want to match the whole word
'the aforementioned word' -cmatch 'for' #grr
# \b to the rescue for whole word only
'the aforementioned word' -cmatch '\bfor\b'
'the for word' -cmatch '\bfor\b'

#Can still use other things with this
'the for word' -cmatch '\bf.r\b'

# I want a sentence that begins with The and ends with dog

# + is one or more therefore .+ is one or more any characters between start with The and end with dog
$string -cmatch '^The.+dog$'
'test ending in dog' -cmatch '^The.+dog$'
'abcdefg' -cmatch '^a.+g$'

# I want what is tested to ONLY be John or Jon. Combine with the ^ and $ (start and end)

'John' -cmatch '^Jo(n|hn)$'
'Jon' -cmatch '^Jo(n|hn)$'
'John Savill' -cmatch '^Jo(n|hn)$'

# * (asterisk) means zero or more
'abcdefg' -cmatch '^a.*g$'
'ag' -cmatch '^a.*g$'
'ag' -cmatch '^a.+g$' # + is one or more remember
'acg' -cmatch '^a.+g$'

# ? means 0 or 1
'ag' -cmatch '^a.?g$'
'acg' -cmatch '^a.?g$'
'abcdefg' -cmatch '^a.?g$'

# Can quantify with {number} or {min,} or {min,max}
'abcdefg' -cmatch '^a.{5}g$'
'abcdefhig' -cmatch '^a.{5}g$'

'abcdefg' -cmatch '^a.{3,}g$'
'abcg' -cmatch '^a.{3,}g$'

'abcdefg' -cmatch '^a.{0,5}g$'
'abcdefhig' -cmatch '^a.{0,5}g$'

'abcdefg' -cmatch '^a.{3,5}g$'
'abcdefhig' -cmatch '^a.{3,5}g$'
'abcg' -cmatch '^a.{3,5}g$'

# \d for a digit
'123-45-6789' -cmatch '\d\d\d-\d\d-\d\d\d\d'
'123-455-6789' -cmatch '\d\d\d-\d\d-\d\d\d\d'
'123-45-67f9' -cmatch '\d\d\d-\d\d-\d\d\d\d'

# Use our quantifier
'123-45-6789' -cmatch '\d{3}-\d{2}-\d{4}'
'1235-45-6789' -cmatch '\d{3}-\d{2}-\d{4}'
# Wait, why. Remember its just looking for that somewhere so finds it after first number
# Could force to just the start to see fail OR we could match on word with \b
'1235-45-6789' -cmatch '^\d{3}-\d{2}-\d{4}'
'123-45-6789' -cmatch '^\d{3}-\d{2}-\d{4}'

# Could replace except the last 4 for example (masking) (notice we make the last 4 an element/capture group by putting in parenthesis)
# We use ( ) when we want to extract/replace this part for some purpose
'putting a SSN 123-45-6789 in here' -replace '\d{3}-\d{2}-(\d{4})','xxx-xx-$1'
'putting a SSN 123-45-6789 in here and 000-54-6234 as well' -replace '\d{3}-\d{2}-(\d{4})','xxx-xx-$1'

# the matches are stored in a hash table that are numerical by default
'123-45-6789' -cmatch '(\d{3})-(\d{2})-(\d{4})'
$Matches

# Check for a valid email format quite lazy. Just looking for @ and a . Escape is \ for the .
'john@savilltech.net' -cmatch '^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+$'
'johnsavilltech.net' -cmatch '^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+$'
'john@savilltechnet' -cmatch '^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+$'
# This is not my actual email and don't check this!

# Want to split it into its parts? Can use the capture groups again
'john@savilltech.net' -cmatch '(^[a-zA-Z0-9]+)@([a-zA-Z0-9]+\.[a-zA-Z0-9]+$)'
Write-Output "User $($Matches[1]) from $($Matches[2])"

# We can name the groups if desired which changes the hash table to the named part using ?<value>
# The exact implementation of this can vary
'john@savilltech.net' -cmatch '(?<user>^[a-zA-Z0-9]+)@(?<domain>[a-zA-Z0-9]+\.[a-zA-Z0-9]+$)'
$Matches

# The official regex for email per RFC 5322
# (?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])

# specials
# []().\^$|?*+{} must all be escaped using \ if want to use as regular characters
'[part]something[\part]' -cmatch '\[[a-z]+\]([a-z]*?)\[\\[a-z]+\]'
$Matches[1]

# \t tab \n new line \s any whitespace

# mix of space and tabs remove from start or end then any character \S is any non whitespace
# therefore \s\S is any character as a character group

# Using ( ) makes them a single element/group so any number of characters as a group
'   whitespaces need to go             ' -cmatch '^\s*([\s\S]*?)\s*$'
Write-Output "-$($Matches[1])-" #this is the inner element of the match
# here we look for space or a tab
'   whitespaces need to go             ' -cmatch '^[ \t]*([\s\S]*?)[ \t]*$'
Write-Output "-$($Matches[1])-"

# Why is it *? for the match?
# * on its own is greedy as is +. it will extend the match as far as it can
# appending ? makes it lazy and allows the end regex looking for whitespace to be actioned by
# backtracking (expensive) and giving up characters to allow the pattern to succeed
'   whitespaces need to go             ' -cmatch '^[ \t]*([\s\S]*)[ \t]*$'
Write-Output "-$($Matches[1])-"

# + is 1 or more remember then another saying 0 or more (*)
'123456789' -cmatch '([0-9]+)[0-9]*'
$Matches[1] #takes them all as its greedy
'123456789' -cmatch '([0-9]+?)[0-9]*'
$Matches[1] #takes the minimum as we made it lazy

# Note even greedy will give up characters for a match if needed and backtracks
'123456789' -cmatch '([0-9]*)[0-9]{2}'
$Matches[1]
# Adding a + makes it possessive and WON'T give up characters if needed so match fails
# Possessive is not supported on .NET so this won't actually work
'123456789' -cmatch '([0-9]*+)[0-9]{2}'
# Instead I can use atomic grouping, ?>. atomic grouping removes all backtracking for the parenthesized group,
# i.e. possessive behavior
'123456789' -cmatch '(?>[0-9]*)[0-9]{2}'
# Match fails since it just took all the numbers and wouldn't backtrack to give 2 back to the rest of the pattern

# Lookahead and lookbehind where a match is only if something is followed by or proceed by another pattern
# Lookbehind using (?<=pattern) . A price in the US has a $ in front. Note I must escape the $ since its a special character
'A cheese pizza costs $10.99 today.' -cmatch '(?<=\$)\d+'
$Matches
# Well it could have zero or one decimal parts. Remember have to escape the . then two decimals and 0 or 1 of them \.\d{2}?
'A cheese pizza costs $10.99 today.' -cmatch '(?<=\$)\d+(\.\d{2})?'
$Matches
# Note there is a slight performance impact to capturing groups. Can make NON capturing with ?:
'A cheese pizza costs $10.99 today.' -cmatch '(?<=\$)\d+(?:\.\d{2})?'
$Matches


# Negative lookbehind means NOT pattern before (?<!)
'A cheese pizza costs €10 today.' -cmatch '(?<!€)\d+'
$Matches
# Make match the whole word \b
'A cheese pizza costs €10 today.' -cmatch '\b(?<!€)\d+\b'
# Still works with previous with word match \b
'A cheese pizza costs $10.99 today.' -cmatch '\b(?<=\$)\d+(\.\d{2})?\b'
$Matches

# Lookahead using (?=pattern). Price in Europe has € behind
'A cheese pizza costs 10€ today.' -cmatch '\d+(?=€)'
$Matches
# What is I want the € captured. Make it a group with ()
'A cheese pizza costs 10€ today.' -cmatch '\d+(?=(€))'
$Matches

# Negative lookahead (?!)
'A cheese pizza costs 10$ today.' -cmatch '\d+(?!\$)'
$Matches
# Grrrr, whole word again
'A cheese pizza costs 10$ today.' -cmatch '\b\d+(?!\$)\b'

# There are other special characters etc
# https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Cheatsheet

# Example of a RegEx I've used \s any whitespace \S any non-whitespace. This means non-greedy ANY character 0 or more times *?
# Then captures ( ) the text I care about between div tags
$regExFindNote = '<div class="column small-12">[\s\S]*?<div class="row column">([\s\S]*?)</div>'