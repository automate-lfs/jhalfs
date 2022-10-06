import pathlib
import pprint
import re

from lxml import etree

cmdFormat = '''#/bin/bash -e
# --- pkg url: {url}

# --- Unclassified commands
{run}
# --- Pre commands
{pre}
# --- Configure commands
{configure}
# --- Make commands
{make}
# --- Test commands
{test}
# --- Install commands
{install}

'''


class JHalfsLFSParser():
    """A class for parsing commands from the LFS book.

        Args:
            xmlFile (string): The name of the file to parse.
            xslFile (string): The name of a profile spreadsheet.
    """

    def __init__(self, xmlFile, xslFile):
        self._xmlFile = xmlFile
        self._xslFile = xslFile

    def run(self):
        pattern = re.compile(r'^ch-(system|tools)-')
        order = 0
        chroot = False
        cmds = list()
        materials = list()

        tree = etree.parse(self._xmlFile)
        tree.xinclude()
        xslt = etree.parse(self._xslFile)
        transform = etree.XSLT(xslt)
        params = {"profile.revision": '"sysv"', "profile.arch": '"default"'}
        newtree = transform(tree, **params)

        for item in newtree.iter():
            if item.tag == "sect1":
                cmd = {"system": False, "chroot": False}
                name = item.get("id")
                if pattern.match(name):
                    if name == "ch-tools-chroot":
                        chroot = True
                        continue
                    if "ch-system-" in name:
                        cmd["system"] = True
                    order += 1
                    cmd["chroot"] = chroot
                    cmd["name"] = "{:03}-{}.sh".format(order, name)

                    sect1info = item.find("sect1info")
                    if sect1info is not None:
                        cmd["pkgUrl"] = sect1info.find("address").text

                    for child in item.iterdescendants("screen"):
                        if child.get("role") != "nodump":
                            for ui in child.iterchildren("userinput"):
                                cmdType = ui.get("remap", default="run")
                                cmd[cmdType] = ui.text

                    cmds.append(cmd)

            if item.tag == "variablelist" and item.get("role") == "materials":
                for child in item.iterchildren("varlistentry"):
                    material = {}
                    for para in child.iterdescendants("para"):
                        if "Download:" in para.text:
                            ulink = para.find("ulink")
                            if ulink is not None:
                                material["url"] = ulink.get("url")
                    if material["url"]:
                        for literal in child.iterdescendants("literal"):
                            if literal.text and len(literal.text) == 32:
                                material["md5"] = literal.text
                            if literal.text and len(literal.text) == 64:
                                material["sha256"] = literal.text
                        materials.append(material)

        for cmd in cmds:
            url = cmd.get("pkgUrl", "")
            run = cmd.get("run", "")
            pre = cmd.get("pre", "")
            configure = cmd.get("configure", "")
            make = cmd.get("make", "")
            test = cmd.get("test", "")
            install = cmd.get("install", "")
            if '{}{}{}{}{}{}{}'.format(
                    url, run, pre, configure, make, test, install) != "":
                dirName = "output/pre-chroot"
                if cmd["chroot"]:
                    dirName = "output/chroot"
                pathlib.Path(dirName).mkdir(parents=True, exist_ok=True)
                fileName = '{}/{}'.format(dirName, cmd["name"])
                output = cmdFormat.format(
                    url=url,
                    run=run,
                    pre=pre,
                    configure=configure,
                    make=make,
                    test=test,
                    install=install
                )
                with open(fileName, 'w') as f:
                    f.write(output)
        pp = pprint.PrettyPrinter(indent=4)
        pp.pprint(materials)
