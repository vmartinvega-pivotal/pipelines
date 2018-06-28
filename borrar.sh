  MD51=$(md5sum pipeline-build.yml | awk '{ print $1 }')
  MD52=$(md5sum pipeline-build.yml | awk '{ print $1 }')
  echo "DEBUG: MD51: ${MD51}"
  echo "DEBUG: MD52: ${MD52}"

  if [ "'${MD51}'" == "'${MD52}'" ]; then
    echo "DEBUG: There are not differencies with the old app-descriptor and the new one, skipping..."
  else
    echo "There are differencies"
  fi
