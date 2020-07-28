#!/usr/bin/env bash

# vars
config='./site.conf'
staticdir='./static'
postsdir='./posts'
tmpdir='/tmp/nablo'
tmpcatdir="${tmpdir}/category"

# functions
die(){ echo "$*" >&2; exit 1; }
lower(){ echo "$*" | tr 'A-Z' 'a-z'; }
get(){ sed '/^-*-*-/q' "${2}" | grep "^${1}:" | cut -d':' -f2- | xargs; }
addtocat(){ ${chronological} && echo "${1}" >> "${2}" || sed "1 a\\${1}" -i "${2}"; }
fdate(){ ${showdate} && echo "$*" | sed -E 's,([0-9]{4})([0-9]{2})([0-9]{2}),<time>\3/\2/\1</time>,'; }
mkmd(){ [ "${1}" == '-s' ] && sed '0,/^-*-*-/d' "${2}" | ${mdparser} || cat "${@}" | ${mdparser}; }

navhtml(){
    for n in ${1}; do
        u=$(echo ${n} | cut -d'~' -f2-)
        l="$(lower "${2}${n}.html")"
        if echo ${u} | grep -q ^http; then
            l="${u}" && n=$(echo ${n} | cut -d'~' -f1)
        fi
        echo "<a href="${l}">${n}</a>"
    done
}

bar(){
    ((elapsed=${1}*${2}/100))
    printf -v prog  "%${elapsed}s"
    printf -v total "%$((${2}-elapsed))s"
    printf '%s\r' "[${prog// /*}${total}] ${1}%"
}

usage(){
    cat <<- EOF
Usage: $(basename "${0}") [OPTIONS]
    -h --help             show this help
    -c --config FILE      use a specific configuration
    -p --posts DIR        use a specific posts directory
    -o --out DIR          use a specific ouput directory
EOF
}

main(){
    while :; do
        case "${1}" in
            -h|--help)     usage; exit 0;;
            -c|--config)   config="${2}"; shift;;
            -p|--posts)    postsdir="${2}"; shift;;
            -o|--out)      staticdir="${2}"; shift;;
            *)             break;;
        esac
        shift
    done
    [ -f "${config}" ] && . "${config}" || die "ERROR: Config file needed"
    [ -d "${postsdir}" ]  || die "ERROR: Posts directory missing"
    [ -z "${mdparser}" ]  && die "ERROR: Markdown parser needed, check ${config}"

    rm -rf "${tmpdir}" "${staticdir}"
    mkdir -p "${tmpcatdir}" "${staticdir}"

    echo "+ collecting categories..."
    for p in "${postsdir}/"*; do
        [ -d "${p}" ] && continue
        category="$(get 'nav' "${p}")"
        ptype="$(get 'type' "${p}")"
        [ "${ptype}" == 'url' ] && u="~$(get 'url' ${p})" || u=''
        if ! echo "${nav}" | grep -q "${category}"; then
            nav="${nav} ${category}${u}"
        fi
    done
    navhtml "${nav}" './' > "${tmpdir}/nav.html"

    echo "+ creating template..."
    cat "${theme}/style.css" > "${tmpdir}/css"
    sed "${theme}/page.html" \
      -e "s,@@URL@@,${url},g" \
      -e "s,@@ICON@@,${icon},g" \
      -e "s,@@TITLE@@,${title},g" \
      -e "s,@@FOOTER@@,${footer},g" \
      -e "s,@@FAVICON@@,${favicon},g" \
      -e "s,@@DESCRIPTION@@,${description},g" \
      -e "/@@CSS@@/{r${tmpdir}/css" -e "d}" \
      -e "/@@NAV@@/{r${tmpdir}/nav.html" -e "d}" \
      > "${tmpdir}/base.html"

    echo "+ creating posts..."
    postno=1
    postsnb=$(find "${postsdir}" -mindepth 1 -maxdepth 1 -name ".*" -prune -o -print | wc -l)
    for p in "${postsdir}/"*; do
        bar $((100*postno/postsnb)) 20 && postno=$((postno+1))
        [ -d "${p}" ] && cp -r "${p}" "${staticdir}/" && continue
        filename="$(basename "${p}" | sed 's,.md$,,')"
        pdate=$(echo ${filename} | cut -d'_' -f1)
        cat="$(get 'nav' "${p}")"
        catl="$(lower "${cat}")"
        ptype="$(get 'type' "${p}")"
        if [ "${ptype}" == 'page' ]; then
            out="${catl}.html"
        else
            out="${filename}.html"
            ! [ -f "${tmpcatdir}/${catl}" ] && echo "# ${cat}" > "${tmpcatdir}/${catl}"
            addtocat "* $(fdate ${pdate})[$(get 'title' "${p}")](${out})" "${tmpcatdir}/${catl}"
        fi
        mkmd -s "${p}" > "${tmpdir}/post.html"
        sed "${tmpdir}/base.html" -e "/@@CONTENT@@/{r${tmpdir}/post.html" -e "d}" > ${staticdir}/${out}
    done; echo

    echo "+ creating categories..."
    for c in "${tmpcatdir}/"*; do
        out="$(basename ${c}).html"
        mkmd "${c}" > "${c}.html"
        sed "${tmpdir}/base.html" -e "/@@CONTENT@@/{r${c}.html" -e "d}" > ${staticdir}/${out}
    done

    fnav=$(echo ${nav} | cut -d' ' -f1)
    ln -s "$(lower "${fnav}.html")" index.html
    mv index.html "${staticdir}/"
}

main "${@}"

