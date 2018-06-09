BRANCHNAME="Hola"

PATCH_LEVEL=$(expr `git tag|grep '${BRANCHNAME}.[0-9][0-9]*\$' | awk -F '.' '{ print $3 }' | sort -n | tail -n 1` + 1 || echo 0)

NEXT_RELEASE=${BRANCHNAME}.${PATCH_LEVEL}

echo "Calculated next release: ${NEXT_RELEASE}"
