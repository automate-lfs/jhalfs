#!/bin/bash
#
# $Id$
#
set -e

# Configuration file for alternatives
source alternatives.conf
[[ $? > 0 ]] && echo -e "\n\tWARNING: alternatives.conf did not load..\n" && exit

# Dependencies module
source func_dependencies
[[ $? > 0 ]] && echo -e "\n\tWARNING: func_dependencies did not load..\n" && exit

#======= MAIN ========

if [[ ! -f packages ]] ; then
  echo -e "\tNo packages file has been found.\n"
  echo -e "\tExecution aborted.\n"
  exit 1
fi

# ID of target package (as listed in packages file)
if [[ -z "$1" ]] ; then
  echo -e "\n\tYou must to provide a package ID."
  echo -e "\tSee packages file for a list of available targets.\n"
  exit 1
elif ! grep  "^$1[[:space:]]" packages > /dev/null ; then
  echo -e "\n\t$1 is not a valid package ID."
  echo -e "\tSee packages file for a list of available targets.\n"
  exit 1
else
  case $1 in
    xorg7 )
      TARGET=xterm2
      echo -e "\n\tUsing $TARGET as the target package"
      echo -e "to build the Xorg7 meta-package."
      ;;
    * )
      TARGET=$1
      echo -e "\n\tUsing $TARGET as the target package."
      ;;
  esac
fi

# Dependencies level 1(required)/2(1 + recommended)/3(2+ optional)
if [[ -z "$2" ]] ; then
  DEP_LEVEL=2
  echo -e "\n\tNo dependencies level has been defined."
  echo -e "\tAssuming level $DEP_LEVEL (Required plus Recommended).\n"
else
  case $2 in
    1 | 2 )
      DEP_LEVEL=$2
      echo -e "\n\tUsing $DEP_LEVEL as dependencies level.\n"
      ;;
    # Prevent circular dependencies when level 3
    # cracklib-->python-->tk-->X-->linux-pam-->cracklib
    # docbook-utils--> Optional dependencies are runtime only
    # libxml2-->libxslt-->libxml2
    # cyrus-sasl-->openldap-->cyrus-sasl
    # alsa-lib-->doxygen-->graphviz-->jdk-->alsa-lib
    # unixodbc-->qt-->unixodbc
    # cups-->php-->sendmail-->espgs-->cups
    # libexif-->graphviz-->php-->libexif
    # esound-->aRts-->esound
    # gimp-->imagemagick-->gimp
    3 )
      case $TARGET in
        cracklib | docbook-utils | libxml2 | cyrus-sasl | alsa-lib | \
        unixodbc | cups | libexif | esound | gimp )
          DEP_LEVEL=2
          echo -e "\n\t$TARGET have circular dependencies at level $2"
          echo -e "\tUsing $DEP_LEVEL as dependencies level.\n"
          ;;
        * )
          DEP_LEVEL=$2
          echo -e "\n\tUsing $DEP_LEVEL as dependencies level.\n"
          ;;
      esac
      ;;
    * )
      DEP_LEVEL=2
      echo -e "\n\t$2 is not a valid dependencies level."
      echo -e "\tAssuming level $DEP_LEVEL (Required plus Recommended).\n"
      ;;
  esac
fi

# Create the working directory and cd into it
mkdir $TARGET && cd $TARGET

# XML file of the target package
PKGXML=`grep "^$TARGET[[:space:]]" ../packages | cut -f2`

# The BLFS sources directory.
BLFS_XML=`echo $PKGXML | sed -e 's,/.*,,'`

if [[ ! -d ../$BLFS_XML ]] ; then
  echo -e "\tThe BLFS book sources directory is missing.\n"
  echo -e "\tExecution aborted.\n"
  cd .. && rmdir $TARGET
  exit 1
fi

# XInclude stuff
ENTRY_START="<xi:include xmlns:xi=\"http://www.w3.org/2003/XInclude\" href=\"../"
ENTRY_END="\"/>"

echo -en "\tGenerating $TARGET dependencies tree ..."

# Create target package dependencies list
case $TARGET in
  # Meta-packages at target level
  # KDE and Gnome-{core,full} could be made via packages.sh, but not sure yet how.
  alsa ) # When target "alsa", use all alsa-* packages
    echo -e "alsa-oss\nalsa-firmware\nalsa-tools\nalsa-utils\n \
             alsa-plugins\nalsa-lib" > dependencies/$TARGET.dep
    ;;
  * ) # Default
    xsltproc --stringparam dependencies $DEP_LEVEL -o dependencies/$TARGET.dep \
             ../dependencies.xsl ../$PKGXML
    ;;
esac

# Start with a clean $TARGET-index.xml.tmp file
> $TARGET-index.xml.tmp

# Write the XInclude
echo -e "    $ENTRY_START$PKGXML$ENTRY_END" >> $TARGET-index.xml.tmp

# Start with a clean depure.txt file
> depure.txt

# If have dependencies, write its XInclude and find sub-dependencies
[[ -f dependencies/$TARGET.dep ]] && \
echo -e "Start loop for PKG $TARGET\n" >> depure.txt && \
mkdir xincludes && do_dependencies $TARGET

echo "done"

echo -en "\tGenerating $TARGET-index.xml ..."

# Header to $TARGET-index.xml
{
cat << EOF
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V4.4//EN"
  "http://www.oasis-open.org/docbook/xml/4.4/docbookx.dtd" >

<book>

  <xi:include xmlns:xi="http://www.w3.org/2003/XInclude" href="../$BLFS_XML/book/bookinfo.xml"/>

  <preface>
    <?dbhtml filename="preface.html" dir="preface"?>

    <title>Preface</title>

    <xi:include xmlns:xi="http://www.w3.org/2003/XInclude" href="../$BLFS_XML/introduction/important/locale-issues.xml"/>
    <xi:include xmlns:xi="http://www.w3.org/2003/XInclude" href="../$BLFS_XML/introduction/important/bootscripts.xml"/>

  </preface>

  <chapter>
    <?dbhtml filename="chapter.html" dir="installing"?>

    <title>Installing $TARGET in Dependencies Build Order</title>

EOF
} > $TARGET-index.xml

# Dump $TARGET-index.xml.tmp in reverse order.
tac $TARGET-index.xml.tmp >> $TARGET-index.xml
rm $TARGET-index.xml.tmp

# Footer of $TARGET-index.xml
{
cat << EOF

  </chapter>

  <xi:include xmlns:xi="http://www.w3.org/2003/XInclude" href="../$BLFS_XML/appendices/creat-comm.xml"/>
  <xi:include xmlns:xi="http://www.w3.org/2003/XInclude" href="../$BLFS_XML/appendices/ac-free-lic.xml"/>

  <index/>

</book>

EOF
} >> $TARGET-index.xml

echo "done"

echo -en  "\tGenerating the HTML book ..."

xsltproc --xinclude --nonet --stringparam base.dir HTML/ \
         --stringparam chunk.quietly 1 \
         ../$BLFS_XML/stylesheets/blfs-chunked.xsl \
         $TARGET-index.xml > xsltproc.log 2>&1
mkdir HTML/{stylesheets,images}
cp ../$BLFS_XML/stylesheets/*.css HTML/stylesheets
cp ../$BLFS_XML/images/*.png HTML/images
cd HTML
sed -i -e "s@../stylesheets@stylesheets@g" *.html
sed -i -e "s@../images@images@g" *.html
for filename in `find . -name "*.html"` ; do
  tidy -config ../../$BLFS_XML/tidy.conf $filename || true
  sh ../../$BLFS_XML/obfuscate.sh $filename
  sed -i -e "s@text/html@application/xhtml+xml@g" $filename
done

echo "done"

echo -en  "\tGenerating the build scripts ... not implemented yet, sorry\n"
