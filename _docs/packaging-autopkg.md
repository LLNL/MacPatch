---
layout: default
title: "Packaging with AutoPkg"
---

# MacPatchImporter for AutoPkg
---

This processor adds the ability to upload AutoPkg packages to a MacPatch server.

## MacPatchImporterProcessor
The MacPatchImporterProcessor recipe is an AutoPkg ["shared recipe processor"](https://github.com/autopkg/autopkg/wiki/Processor-Locations#shared-recipe-processors). It's a "stub" recipe that makes the MacPatchImporter processor available to your other recipes. The other ".macpatch" recipes in this repo use that stub to access the "MacPatchImporterProcessor.py" processor.

## Setup
You must have [AutoPkg](https://github.com/autopkg/autopkg/releases/latest) installed and the main recipe repo added.

    autopkg repo-add http://github.com/autopkg/recipes.git


You can find more information on AutoPkg [here](http://autopkg.github.io/autopkg/).<br>
I recommend also using [AutoPkgr](http://www.lindegroup.com/autopkgr), which is an excellent GUI front end to AutoPkg.

### Add the MacPatch repo

    autopkg repo-add https://github.com/SMSG-MAC-DEV/MacPatch-AutoPKG.git

### Configure MacPatch environment settings
Some settings can be set for all .macpatch recipes in the AutoPkg preferences.

    defaults write com.github.autopkg MP_URL https://macpatch.company.com
    defaults write com.github.autopkg MP_USER autopkg
    defaults write com.github.autopkg MP_PASSWORD password

Environments using self signed certificates should set the following key.

    defaults write com.github.autopkg MP_SSL_VERIFY -bool NO


#### Create override for a recipe
It's best to use [overrides](https://github.com/autopkg/autopkg/wiki/Recipe-Overrides) to set the recipe specific inputs for your environment.

    autopkg make-override Firefox.macpatch

Only keep the keys that you alter. Remove any unchanged keys from the override file.

## Input keys

**patch_name**

* Patch name for use in MacPatch.

*Example:*

{% highlight XML %}
<key>patch_name</key>
<string>Firefox</string>
{% endhighlight %}

**patch_id**

* MacPatch bundle ID.

*Example:*

```xml
<key>patch_id</key>
<string>org.mozilla.firefox</string>
```

**description**

* A description for the patch in MacPatch.

*Example:*

```xml
<key>description</key>
<string>Firefox browser.</string>
```


**description_url**

* A url to find more info on the patch.

*Example:*

```xml
<key>description_url</key>
<string>http://www.mozilla.org/en-US/firefox/</string>
```


**patch_vendor**

* The name of the patch vendor.

*Example:*

```xml
<key>patch_vendor</key>
<string>Mozilla</string>
```


**patch_severity**

* Severity of the patch.
* Valid values:
  * High
  * Medium
  * Low
  * Unknown

*Example:*

```xml
<key>patch_severity</key>
<string>High</string>
```


**OSType**

* Which OS types is the patch valid for. Having the Server.app installed makes it a Sever.
* Valid values:
  * "Mac OS X, Mac OS X Server"
  * "Mac OS X"
  * "Mac OS X Server"

*Example:*

```xml
<key>OSType</key>
<string>Mac OS X, Mac OS X Server</string>
```


**OSVersion**

* Comma separated list of OS versions to apply the patch to.
* Possible values:
  * "10.10.\*"
  * "10.9.\*, 10.10.\*"
  * Use "\*" for all versions

*Example:*

```xml
<key>OSVersion</key>
<string>10.10.*</string>
```


**patch_criteria**

* An array of patch criteria.
<br>See MacPatch [docs](https://macpatch.github.io/documentation/custom-patch-content.html#patch_criteria_lang) for more info.

*Example:*

```xml
<key>patch_criteria</key>
<array>
    <string>File@Exists@/Applications/Firefox.app@True</string>
    <string>File@VERSION@/Applications/Firefox.app@#version#;LT</string>
</array>
```


**patch_criteria_scripts**

* True/False key to indicate if patch criteria scripts are used.
<br>Scripts are not included directly in the recipe xml. Instead they are placed into a "scripts" sub-folder of the recipe and the corresponding key in the recipe is set to true.
<br>If this key is set to true, the processor will look for any files with a `.criteria-script` file extension in the `./scripts` folder.
<br>You can have any number of criteria scripts as long as they have `.criteria-script` file extension. ex: script1.criteria-script, script2.criteria-script

*Example:*

```xml
<key>patch_criteria_scripts</key>
<true/>
```


**pkg_preinstall**

* True/False key to indicate if a patch pre-install script is used.
<br>Scripts are not included directly in the recipe xml. Instead they are placed into a "scripts" sub-folder of the recipe and the corresponding key in the recipe is set to true.
<br>If this key is set to true, the processor will look a file named `preinstall.script` in the `./scripts` folder.

*Example:*

```xml
<key>pkg_preinstall</key>
<true/>
```


**pkg_postinstall**

* True/False key to indicate if a patch post-install script is used.
<br>Scripts are not included directly in the recipe xml. Instead they are placed into a "scripts" sub-folder of the recipe and the corresponding key in the recipe is set to true.
<br>If this key is set to true, the processor will look a file named `postinstall.script` in the `./scripts` folder.

*Example:*

```xml
<key>pkg_postinstall</key>
<false/>
```


**pkg_env_var**

* Environment variables to set before patch executes.

*Example:*

```xml
<key>pkg_env_var</key>
<string>myvar=1,tdir=/tmp/</string>
```


**patch_install_weight**

* A number between 1 to 100. Patches are ordered for install by this number. Default is 30. Change this value to control the order it will install.

*Example:*

```xml
<key>patch_install_weight</key>
<string>30</string>
```


**patch_reboot**

* Set if patch requires a reboot. Notice this key is not True/False, instead its Yes/No

*Example:*

```xml
<key>patch_reboot</key>
<string>No</string>
```

#### Example recipe
Below is a sample Firefox recipe with the needed inputs to upload to a MacPatch server.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Description</key>
	<string>Uploads Firefox into MacPatch</string>
	<key>Identifier</key>
	<string>com.github.smsg-mac-dev.macpatch.firefox</string>
	<key>Input</key>
	<dict>
		<key>OSType</key>
		<string>Mac OS X, Mac OS X Server</string>
		<key>OSVersion</key>
		<string>*</string>
		<key>description</key>
		<string>Firefox web browser</string>
		<key>description_url</key>
		<string>http://www.mozilla.org/en-US/firefox/</string>
		<key>patch_criteria</key>
		<array>
			<string>File@Exists@/Applications/Firefox.app@True</string>
			<string>File@VERSION@/Applications/Firefox.app@32.0.0;GTE</string>
			<string>File@VERSION@/Applications/Firefox.app@#version#;LT</string>
		</array>
		<key>patch_criteria_scripts</key>
		<false/>
		<key>patch_id</key>
		<string>org.mozilla.firefox</string>
		<key>patch_install_weight</key>
		<string>30</string>
		<key>patch_name</key>
		<string>Firefox</string>
		<key>patch_reboot</key>
		<string>No</string>
		<key>patch_severity</key>
		<string>High</string>
		<key>patch_vendor</key>
		<string>Mozilla</string>
		<key>pkg_env_var</key>
		<string></string>
		<key>pkg_postinstall</key>
		<false/>
		<key>pkg_preinstall</key>
		<true/>
	</dict>
	<key>MinimumVersion</key>
	<string>0.2.0</string>
	<key>ParentRecipe</key>
	<string>com.github.autopkg.pkg.Firefox_EN</string>
	<key>Process</key>
	<array>
		<dict>
			<key>Processor</key>
			<string>com.github.smsg-mac-dev.MacPatchImporterProcessor/MacPatchImporterProcessor</string>
		</dict>
	</array>
</dict>
</plist>
```
