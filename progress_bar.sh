#!/bin/bash
progress_bar() {
	local current=0
	local max=100
	local completed_char="#"
	local uncompleted_char="."
	local decimal=1
	local prefix=" ["
	local suffix="]"
	local percent_sign="%"
	local max_width=$(tput cols)

	local complete remain subtraction width atleast percent chars
	local padding=3

	local OPTIND

	while getopts c:u:d:p:s:%:m:hV flag; do
		case "$flag" in
			c) completed_char="$OPTARG";;
			u) uncompleted_char="$OPTARG";;
			d) decimal="$OPTARG";;
			p) prefix="$OPTARG";;
			s) suffix="$OPTARG";;
			%) percent_sign="$OPTARG";;
			m) max_width="$OPTARG";;

			(h) lib_help;;
			(V) echo "$lib_script_name: version $Revision$ ($Date$)"; exit 0;;
			(*) lib_usage;;
		esac
	done
	shift $((OPTIND-1))

	current=${1:-$current}
	max=${2:-$max}

	if (( decimal > 0 )); then
		(( padding = padding + decimal + 1 ))
	fi

	let subtraction=${#completed_char}+${#prefix}+${#suffix}+padding+${#percent_sign}
	let width=max_width-subtraction

	if (( width < 5 )); then
		(( atleast = 5 + subtraction ))
		echo >&2 "the max_width of ($max_width) is too small, must be atleast $atleast"
		return 1
	fi

    if (( current > max ));then
        echo >&2 "current value must be smaller than max. value"
        return 1
    fi

    percent=$(awk -v "f=%${padding}.${decimal}f" -v "c=$current" -v "m=$max" 'BEGIN{printf('f', c / m * 100)}')

    (( chars = current * width / max))

    # sprintf n zeros into the var named as the arg to -v
    printf -v complete '%0*.*d' '' "$chars" ''
    printf -v remain '%0*.*d' '' "$((width - chars))" ''

    # replace the zeros with the desired char
    complete=${complete//0/"$completed_char"}
    remain=${remain//0/"$uncompleted_char"}

    printf '%s%s%s%s %s%s\r' "$prefix" "$complete" "$remain" "$suffix" "$percent" "$percent_sign"

	if (( current >= max )); then
		echo ""
	fi
}

if [ ! -z $1 ] && [ $lib_script_name = "lib_main" ]; then
	"$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}" "${14}" "${15}"
fi
