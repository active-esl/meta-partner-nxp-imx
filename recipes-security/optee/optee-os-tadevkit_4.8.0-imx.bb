# The generic tadevkit recipe includes the selected matching OP-TEE recipe.
PV = "4.8.0-imx"

require recipes-security/optee/optee-os-tadevkit_4.4.0.bb

DEFAULT_PREFERENCE = "-1"
