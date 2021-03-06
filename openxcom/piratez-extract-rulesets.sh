#!/bin/bash
shopt -s nullglob

game_dirs=( "$@" )
[[ ${#game_dirs[@]} -gt 0 ]] \
	|| game_dirs=( {OpenXcom,Dioxine}_XPiratez* )

usage() {
	bin=$(basename $0)
	echo >&2 "Usage: $bin [gamedir]"
	echo >&2 "If no gamedir specified,"
	echo >&2 "  {OpenXcom,Dioxine}_XPiratez* gets looked-up in current dir."
	exit ${1:-0}
}
[[ "${#game_dirs[@]}" -eq 0 || "$1" = -h || "$1" = --help ]] && usage

rul= rul_dir=
while read v d; do
	v="$d"/user/mods/Piratez/Language/en-US.yml
	[[ -f "$v" ]] || { echo >&2 "Missing en-US.yml with version in $d"; exit 1; }
	v=$(awk 'match($0,/^ *STR_OPENXCOM: .* (\S+)\"$/,a) {sub(/^v\.?/,"",a[1]); print a[1]}' "$v")
	rul=ruleset_"$v".yaml rul_dir=$d
	[[ -e "$rul" ]] && continue
	echo "--- $rul"
	cp "$d"/user/mods/Piratez/Ruleset/Piratez.rul "$rul"
	sed -i -e '/^ \+\(categor\(y\|ies\)\|weight\|listOrder\): /d' -e 's/\r//g' "$rul"
done < <(
	awk -F_ '{print $NF, $0}' \
		< <(for d in "${game_dirs[@]}"; do echo "$d"; done) |
	sort -V )

[[ -z "$rul" ]] || {
	echo "Creating calc-cache: ${rul}.cache.json"
	./piratez-melee-calc.py "$rul".cache.json \
			-r "$rul_dir"/user/mods/Piratez/Ruleset/Piratez.rul \
			-m "$rul_dir"/user/mods/Piratez/Ruleset/'Gun CqC'.rul \
			-l "$rul_dir"/user/mods/Piratez/Language/en-US.yml \
		|| echo >&2 "ERROR: failed to create calc-cache json!!!"
}
