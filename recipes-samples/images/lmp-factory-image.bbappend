# Do not rely solely on the generic lmp-partner-image.inc compatibility name:
# a product layer can provide the same BBPATH entry and win include lookup.
# The uniquely named partner policy is therefore attached explicitly here.
require recipes-samples/images/lmp-partner-nxp-imx-image.inc
