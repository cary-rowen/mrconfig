addon2settings() {
    isAddonOrDie
    hasStableBranchOrDie
	addonName=$(basename $PWD)
    cd $PATH2TOPDIR/srt
    ls -1 */settings | while read file; do
        lang=$(dirname $file)
        logMsg "Setting default value for ${addonName} in $file"
        python scripts/db.py -f $file --set_default addon.${addonName} 0
    done
}

addon2svn() {
    isAddonOrDie
    hasStableBranchOrDie
	addonName=$(basename $PWD)
	logMsg "Running addon2svn for $addonName"
	scons pot mergePot
	cp *.pot /tmp/
    ADDONDIR="$(pwd)"
    cd $PATH2TOPDIR/srt
    ls -1 */settings | while read file; do
        lang=$(dirname $file)
        want=$(python scripts/db.py -f $file -g addon.${addonName})
        logMsg "$lang wants ${addonName}: $want"
        if [ "$want" != "1" ]; then
            continue
        fi
        if [ ! -d $lang/add-ons/${addonName} ]; then
            logMsg "Wanted, but not already in svn, providing it."
            svn mkdir $lang/add-ons/${addonName}
            cp /tmp/${addonName}.pot $lang/add-ons/${addonName}/nvda.po
            sed -i -e "s/Language: /Language: $lang/g" $lang/add-ons/${addonName}/nvda.po
            msgmerge --no-location -U $lang/add-ons/${addonName}/nvda.po /tmp/${addonName}-merge.pot
            svn add $lang/add-ons/${addonName}/nvda.po
            svn commit -m "${lang}: ${addonName} ready to be translated."  $lang/add-ons/${addonName}/nvda.po
        else
            logMsg "Already available for translation, merging in new messages."
            msgmerge --no-location -U $lang/add-ons/${addonName}/nvda.po /tmp/${addonName}-merge.pot
            svn commit -m "${lang}: ${addonName} merged in new messages."  $lang/add-ons/${addonName}/nvda.po
        fi
    done
    cd "$ADDONDIR"
}
