#!/usr/bin/python2.7
"""usage: <inputfile.xml> <context>

Will replace values in inputfile with vvalues from context. A .bak of the
inputfile will be created as well.

The context file should take the following format with one replacement per
line.

<xpath expression>: replacement text

For example:

//property[@name='bindAddress']: 0.0.0.0

This replaces the matched nodes text value. Most XML documents include
namespaces. The input documents default namespace can be referenced in your
xpath expressions with '_' as the prefix, so for example if the default ns is
{urn:jboss:bean-deployer:2.0} supplying an xpath expression of

//_:property

will match {urn:jboss:bean-deployer:2.0}property. This is supported because XPath has
no notion of a default namespace.

If the xpath expression begins with a '+' (plus) the match is treated as
the parent of a newly created node and the line should take the following format

+<xpath of parent>:newtag:value

This will create and append a new element under each xpath match of the newtag
with the text value. To only replace the 1st element use [0] in your xpath.

If the xpath starts with ! (bang) the match will create the new node if doesn't
exist but will replace the value of the node if it does.

Lines starting with @ include that we should set a new attribute value on
matching nodes. This form takes the name of the target attribute and its value. It
is assumed that the attr is in the default namespace at this time.

@//param[name='File']:value:/tmp/log.txt

This would look for a param node with a name=File attribute and add/replace
the value of a 'value' attribute with /tmp/log.txt

"""
from __future__ import print_function
from lxml import etree
import argparse
import os
import tempfile

__author__ = 'benjamin.saller@canonical.com'

log = print

def noop(*args, **kwargs):
    pass

def xpath_attr(root, path, target, value, namespaces):
    nodes = root.xpath(path, namespaces=namespaces)
    log('attr:', path, target, value, nodes)
    for node in nodes:
        node.set(target, value)

def xpath_sub(root, path, value, namespaces):
    nodes = root.xpath(path, namespaces=namespaces)
    log('sub:', path, value, nodes)
    for node in nodes:
        node.text = value

def xpath_new(root, path, tag, value, namespaces):
    nodes = root.xpath(path, namespaces=namespaces)
    log('new:', path, tag, value, nodes)
    for node in nodes:
        etree.SubElement(node, tag).text = value

def xpath_replace(root, path, tag, value, namespaces):
    nodes = root.xpath(path, namespaces=namespaces)
    log('replace:', path, tag, value, nodes)
    for node in nodes:
        if node.find(tag) is not None:
            node = node.find(tag)
            node.text = value
        else:
            etree.SubElement(node, tag).text = value

def execContext(specs, root,  nsmap):
    if not nsmap:
        nsmap = None
    for line in specs.split('\n'):
        if line.startswith('#') or not line: continue

        # Yield back a program with normalized arguments
        # for each replacement directive in the context file
        prog = None
        args = {'root': root, 'namespaces': nsmap}
        path, tag, value = None, None, None
        target = None

        if line.startswith('+'):
            line = line[1:]
            path, tag, value = line.rsplit(':', 2)
            prog = xpath_new
        elif line.startswith('!'):
            line = line[1:]
            path, tag, value = line.rsplit(':', 2)
            prog = xpath_replace
        elif line.startswith('@'):
            line = line[1:]
            path, target, value = line.rsplit(':', 2)
            prog = xpath_attr
        else:
            path, value = line.rsplit(':', 1)
            prog = xpath_sub

        # Normalize all the arguments
        if not nsmap or '_' not in nsmap:
            # If there wes no default namespace in teh
            # parsed document we can remvoe any _: from
            # the path. We can do this without delving
            # deeply into the complexities of XML/XPath
            path = path.replace('_:', '')
        args['path'] = path
        if target: args['target'] = target.strip()
        if tag: args['tag'] = tag.strip()
        args['value'] = value.strip()

        # Invoke the program with the normalized arguments
        prog(**args)

def template(templateFile, contextData, verbose=False):
    """
    Execute a list of funcs taking a etree root
    """
    tree = etree.parse(templateFile)
    root = tree.getroot()
    nsmap = root.nsmap.copy()
    if None in nsmap:
        # alias the default namespace to ns
        nsmap['_'] = nsmap[None]
        del nsmap[None]

    #It is only with this map in place that we can interpret the funcs
    execContext(contextData, root, nsmap)
    return etree.tostring(root, pretty_print=True)


def main():
    global log
    parser = argparse.ArgumentParser(prog="xml-template", description=__doc__)
    parser.add_argument('-v', '--verbose', dest="verbose", action='store_true')
    parser.add_argument('-n', '--no-backup', dest="backup", action='store_false')
    parser.add_argument('template', type=argparse.FileType('r'))
    parser.add_argument('context', type=argparse.FileType('r'))
    options = parser.parse_args()

    if options.verbose is False:
        log = noop

    inputFile = options.template
    contextFile = options.context

    fd, outputFile = tempfile.mkstemp()
    contextData = contextFile.read()

    # Write and swap
    output = template(inputFile, contextData, verbose=options.verbose)
    os.write(fd, '<?xml version="1.0" encoding="UTF-8"?>\n')
    os.write(fd, output)
    os.close(fd)
    if options.backup is not False:
        os.rename(inputFile.name, inputFile.name + '.bak')
    else:
        os.unlink(inputFile.name)

    os.rename(outputFile, inputFile.name)


if __name__ == '__main__':
    main()
