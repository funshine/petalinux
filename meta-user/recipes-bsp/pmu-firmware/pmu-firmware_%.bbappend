#Add debug for PMUFW
#XSCTH_BUILD_DEBUG = "1"

ULTRA96_VERSION = "2"
YAML_COMPILER_FLAGS_append_ultra96-zynqmp = "-DENABLE_MOD_ULTRA96 -DENABLE_SCHEDULER -DENABLE_DIRECT_POWEROFF_ULTRA96"
YAML_COMPILER_FLAGS_append_ultra96-zynqmp = "${@bb.utils.contains('ULTRA96_VERSION', '2', ' -DULTRA96_VERSION=2', ' -DULTRA96_VERSION=1', d)}"
