# XML Template helpers
# The xml-template helper uses _: as the default document namespace.
# These helpers include reference to the default namespace (which will be
# stripped out if there is no default). This is done in such a way to fit current
# requirements but doesn't support using non-default namespaces. To use
# a non-default namespace write the directive with the document's ns prefix
# directly (foregoing the use of these helpers)

property() {
    echo "//_:property[@name='$1']: $2"
}

tag() {
    echo "//_:$1: $2"
}

replace() {
    echo "!//_:$1:$2:$3"
}

attr() {
    # tag, attr, attrValue, newAttr, value
    echo "@//$1[@$2='$3']:$4:$5"
}


