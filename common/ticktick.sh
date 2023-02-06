#!/usr/bin/env bash

ARGV=$@
GREP=grep
EGREP=egrep

# Support {{ 
# // The following code is to make sure
# // that this runs on various platforms as suggested.
# See https://github.com/kristopolous/TickTick/issues/26
if [[ `uname` == "SunOS" ]]; then
  GREP=ggrep
  EGREP=gegrep
fi
# }} End support

__tick_error() {
  echo "TICKTICK PARSING ERROR: "$1
}

# This is from https://github.com/dominictarr/JSON.sh
# See LICENSE for more info. {{{
__tick_json_tokenize() {
  local ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
  local CHAR='[^[:cntrl:]"\\]'
  local STRING="\"$CHAR*($ESCAPE$CHAR*)*\""
  local VARIABLE="\\\$[A-Za-z0-9_]*"
  local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
  local KEYWORD='null|false|true'
  local SPACE='[[:space:]]+'
  $EGREP -ao "$STRING|$VARIABLE|$NUMBER|$KEYWORD|$SPACE|." --color=never | $EGREP -v "^$SPACE$"  # eat whitespace
}

__tick_json_parse_array() {
  local index=0
  local ary=''

  read -r Token

  case "$Token" in
    ']') ;;
    *)
      while :
      do
        __tick_json_parse_value "$1" "`printf "%012d" $index`"

        (( index++ ))
        ary+="$Value" 

        read -r Token
        case "$Token" in
          ']') break ;;
          ',') ary+=_ ;;
          *) 
            __tick_error "Array syntax malformed"
            break ;;
        esac
        read -r Token
      done
      ;;
  esac
}

__tick_json_parse_object() {
  local key
  local obj=''
  read -r Token

  case "$Token" in
    '}') ;;
    *)
      while :
      do
        # The key, it should be valid
        case "$Token" in
          '"'*'"'|\$[A-Za-z0-9_]*) key=$Token ;;
          # If we get here then we aren't on a valid key
          *) 
            __tick_error "Object without a Key"
            break
            ;;
        esac

        # A colon
        read -r Token

        # The value
        read -r Token
        __tick_json_parse_value "$1" "$key"
        obj+="$key:$Value"        

        read -r Token
        case "$Token" in
          '}') break ;;
          ',') obj+=_ ;;
        esac
        read -r Token
      done
    ;;
  esac
}

__tick_json_sanitize_value() {
  value=""
  IFS=
  while read -r -n 1 token; do
    case "$token" in
      [\-\\\"\;,=\(\)\[\]{}.\':\ ]) 
        value+=`printf "%d" \'$token` 
        ;;
      *)
        value+="$token"
        ;;
    esac
  done
  echo $value
}

__tick_json_parse_value() {
  local start=${1/%\"/}
  local end=${2/#\"/}

  local jpath="${start:+${start}_}$end"
  local prej=${jpath/#\"/}
  prej=${prej/%\"/}

  prej="`echo $prej | __tick_json_sanitize_value`"
  [[ "$prej" ]] && prej="_$prej"

  case "$Token" in
    '{') __tick_json_parse_object "$jpath" ;;
    '[') __tick_json_parse_array  "$jpath" ;;

    *) 
      Value=$Token 
      Path="$Prefix$prej"
      Path=${Path/#_/}
      echo __tick_data_${Path// /}=$Value 
      ;;
  esac
}

__tick_json_parse() {
  read -r Token
  __tick_json_parse_value
  read -r Token
}
# }}} End of code from github

# Since the JSON parser is just json parser, and we have a runtime
# and assignments built on to this, along with javascript like referencing
# there is a two-pass system, just because it was easier to code.
#
# This one separates out the valid JSON from the runtime library support
# and little fo' language that this is coded in.
__tick_fun_tokenize_expression() {
  CHAR='[0-9]*[A-Za-z_$][0-9]*'
  FUNCTION="(push|pop|shift|items|delete|length)[[:space:]]*\("
  NUMBER='[0-9]*'
  STRING="$CHAR($CHAR)*"
  PAREN="[()]"
  QUOTE="[\"\'\\]"
  SPACE='[[:space:]]+'
  $EGREP -ao "$FUNCTION|$STRING|$QUOTE|$PAREN|$NUMBER|$SPACE|." --color=never |\
    sed "s/^/S/g;s/$/E/g" # Make sure spaces are respected
}

__tick_fun_parse_expression() {
  
  quoteToken=""
  backslash=0

  while read -r token; do
    token=${token#S}
    token=${token%E}

    if [[ $done ]]; then
      suffix+="$token"
    else
      if [[ -z $quoteToken ]]; then
        case "$token" in
          #
          # The ( makes sure that you can do key.push = 1, not that you would, but
          # avoiding having reserved words lowers the barrier to entry.  Try doing
          # say function debugger() {} in javascript and then run it in firefox. That's
          # a fun one.
          #
          # So, it's probably better to be as lenient as possible when dealing with
          # syntax like this.
          #
          'push('|'pop('|'shift('|'items('|'delete('|'length(') function=$token ;;
          ')') 
            function=${function/%(/}

            # For a rational of the method below see: 
            # https://github.com/kristopolous/TickTick/wiki/Function-Logic
            case $function in
              items) echo '${!__tick_data_'"$Prefix"'*}' ;;
              delete) echo 'unset __tick_data_'${Prefix/%_/} ;;
              pop) echo '"$( __tick_runtime_last ${!__tick_data_'"$Prefix"'*} )"; __tick_runtime_pop ${!__tick_data_'"$Prefix"'*}' ;;
              shift) echo '`__tick_runtime_first ${!__tick_data_'"$Prefix"'*}`; __tick_runtime_shift ${!__tick_data_'"$Prefix"'*}' ;;
              length) echo '`__tick_runtime_length ${!__tick_data_'"$Prefix"'*}`' ;;
              *) echo "__tick_runtime_$function \"$arguments\" __tick_data_$Prefix "'${!__tick_data_'"$Prefix"'*}'
            esac
            unset function

            return
            ;;

          [0-9]*[A-Za-z]*[0-9]*) [[ -n "$function" ]] && arguments+="$token" || Prefix+="$token" ;;
          [0-9]*) Prefix+=`printf "%012d" $token` ;;
          '['|.) Prefix+=_ ;;

          [\"\'])
            quoteToken=$token
            ;;
            
          [\[\]]) ;;
          =) done=1 ;;
          # Only respect a space if its in the args.
          ' ') [[ -n "$function" ]] && arguments+="$token" ;;
          *) [[ -n "$function" ]] && arguments+="$token" || Prefix+="$token" ;;
        esac
      else
        case "$token" in
          \\)
            if (( backslash < 0 )); then
              backslash=2 
            fi
            # The other tokenizer preserves the backslashes, so we will too. 
            Prefix+="$token" 
            ;;

          $quoteToken)
            if (( backslash < 0 )); then
              quoteToken=""
            else
              Prefix+="$token" 
            fi
            ;;
          *) Prefix+=$(echo "$token" | __tick_json_sanitize_value) ;;
        esac
        (( backslash -- ))
      fi
    fi
  done

  if [[ "$suffix" ]]; then
    echo "$suffix" | __tick_json_tokenize | __tick_json_parse
  else
    Prefix="`echo $Prefix | __tick_json_sanitize_value`"
    echo '${__tick_data_'$Prefix'}'
  fi
}

__tick_fun_parse_tickcount_reset() {
  # If the tick count is 1 then the backtick we encountered was a 
  # shell code escape. These ticks need to be preserved for the script.
  if (( ticks == 1 )); then
    code+='`'
  fi

  # This resets the backtick counter so that `some shell code` doesn't
  # trip up the tokenizer
  ticks=0
}

# The purpose of this function is to separate out the Bash code from the
# special "tick tick" code.  We do this by hijacking the IFS and reading
# in a single character at a time
__tick_fun_parse() {
  IFS=

  # code oscillates between being bash or tick tick blocks.
  code=''

  # By using -n, we are given that a newline will be an empty token. We
  # can certainly test for that.
  while read -r -n 1 token; do
    case "$token" in
      '`') 

        # To make sure that we find two sequential backticks, we reset the counter
        # if it's not a backtick.
        if (( ++ticks == 2 )); then

          # Whether we are in the stanza or not is controlled by a different
          # variable
          if (( tickFlag == 1 )); then
            tickFlag=0
            [[ "$code" ]] && echo -n "`echo $code | __tick_fun_tokenize_expression | __tick_fun_parse_expression`"
          else
            tickFlag=1
            echo -n "$code"
          fi

          # If we have gotten this deep, then we are toggling between backtick
          # and bash. So se should unset the code.
          unset code
        fi
        ;;

      '') 
        __tick_fun_parse_tickcount_reset

        # this is a newline. If we are in ticktick, then we want to consume
        # them for the parser later on. If we are in bash, then we want to
        # preserve them.  We do this by emitting our buffer and then clearing
        # it
        if (( tickFlag == 0 )); then
          echo "$code"
          unset code
        fi

        ;;

      *) 
        __tick_fun_parse_tickcount_reset
        
        # This is a buffer of the current code, either bash or backtick
        code+="$token"
        ;;
    esac 
  done
}

# The code tokenization and interpretation of bash code.  This
# can be passed a path to be interpreted or, if that is not passed
# it figures out the caller and just does the same thing
#
# If two arguments are called, then the second acts as a signal to
# print the tokenized ticktick code and exit.
#
# This means in a language with declared arguments the signature
# would look like this:
#
#   __tick_fun_tokenize(path_name, set_to_return_and_not_execute) {
#
__tick_fun_tokenize() {
  [[ $# -eq "0" ]] && __tick_fun_tokenize "$(caller 1 | cut -d ' ' -f 3)"
  local fname="$1"

  # This makes sure that when we rerun the code that we are
  # interpreting, we don't try to interpret it again.
  export __tick_var_tokenized=1

  # Using bash's caller function, which is for debugging, we
  # can find out the name of the program that called us. We 
  # then cat the calling program and push it through our parser
  local code=$(cat $fname | __tick_fun_parse)

  # Before the execution we search to see if we emitted any parsing errors
  hasError=`echo "$code" | $GREP "TICKTICK PARSING ERROR" | wc -l`

  if [ "$__tick_var_debug" -o $# -eq 2 ]; then
    printf "%s\n" "$code"
    exit 0
  fi

  # If there are no errors, then we go ahead
  if (( hasError == 0 )); then
    # Take the output and then execute it

    bash -c "$code" -- $ARGV
  else
    echo "Parsing Error Detected, see below"

    # printf observes the new lines
    printf "%s\n" "$code"
    echo "Parsing stopped here."
  fi

  exit
}

## Runtime {
if [[ $__tick_var_tokenized ]]; then 
  enable -n source
  enable -n .
  source() {
    source_temp_path=`mktemp`
    ( __tick_fun_tokenize "$1" "debug" ) > $source_temp_path

    enable source
    builtin source "$source_temp_path"
    enable -n source

    unlink $source_temp_path
  }
  .() {
    source "$1"
  }

  __tick_runtime_length() { echo $#; }
  __tick_runtime_first() { echo ${!1}; }
  __tick_runtime_last() { eval 'echo $'${!#}; }
  __tick_runtime_pop() { eval unset ${!#}; }

  __tick_runtime_shift() {
    local left=
    local right=

    for (( i = 1; i <= $# + 1; i++ )) ; do
      if [ "$left" ]; then
        eval "$left=\$$right"
      fi
      left=$right
      right=${!i}
    done
    eval unset $left
  }
  __tick_runtime_push() {
    local value="${1/\'/\\\'}"
    local base=$2
    local lastarg=${!#}

    let nextval=${lastarg/$base/}+1
    nextval=`printf "%012d" $nextval`

    eval $base$nextval=\'$value\'
  }

  tickParse() {
    eval `echo "$1" | __tick_json_tokenize | __tick_json_parse | tr '\n' ';'`
  }

  tickVars() {
    local tick_vars_opt='' sup_ln_number='' sup_trailing_nl='' indent="  "

    # Process commandline flags
    OPTIND=1
    while getopts ':hiln' tick_vars_opt; do
      case $tick_vars_opt in
        h)
        cat 1>&2 <<-"ENDHELP"
		USAGE: tickVars [-hiln]
		-h: Emit this usage information.
		-i: Suppress the indentation that usually precedes each line of output.
		-l: Suppress the line number information that usually appears at the beginning of output.
		-n: Suppress the blank line which usually prints at the end of output.
		ENDHELP
        exit 0
        ;;
        i) indent="" ;;
        l) sup_ln_number=yes ;;
        n) sup_trailing_nl=yes ;;
      esac
    done

    [[ -z "$sup_ln_number" ]] && echo "@ Line `caller | sed s/\ NULL//`:"
    set | sed -nr /^__tick_data_/s/^__tick_data_/"$indent"/p
    [[ -z "$sup_trailing_nl" ]] && echo
    return 0
  }

  tickReset() {
    for var in `set | sed -nr 's/^(__tick_data_[^=]+).*/\1/p'`
      do unset "$var"
    done
  }
else 
  __tick_fun_tokenize
fi