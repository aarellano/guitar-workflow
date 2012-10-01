#----------------------
#
# BASIC WORKFLOW
#
# Workflow for an AUT on local host
# Precondition: GUITAR and tools installed
#
#----------------------

# Initialize a standard directory layout for AUT
common-init-dir.sh <aut-name>

# Check out the AUT from respective remote location
common-checkout.sh <aut-name>

# Build AUT locally
common-build.sh <aut-name>

# Instrument AUT
common-inst.sh <aut-name>

# Verify build and instrumentation
common-build-check.sh <aut-name>

# Rip the AUT
common-rip.sh <aut-name> <xvfb-tmp-dir> <xvfb-lib-path> <xvfb-cmd>

# Generate EFG from ripped GUI
common-gui2efg.sh <aut-name> <efg-type>

# Generate Gephi graph from RFG
common-efg2gephipdf.sh <aut-name>

# Generate test cases
common-tc-gen-sq.sh <aut-name> <testcase-length> <# testcases>

# Replay testcases
common-replay.sh <aut-name> <.GUI-path> <.EFG-path> <testsuites-path> <testsuite-name> <xvfb-tmp-dir> <xvfb-lib-path> <xvfb-cmd> [archive-username] [archive-hostname] [archive-auts-dir]

# Generate html coverage report (optional)
common-ser2html.sh <aut-name>


#----------------------
# STANDARD WORKFLOW
#----------------------

# Test the cluster for dead hosts
cluster-test.sh <host-config-file>

# Setup AUT on remote machines
cluster-setup.sh <aut-name> <host-config-file>

---
# Generate testcases and store in archive machine
# Any other method for testcase generation may be used
cluster-tc-gen-sq.sh <aut-name> <host-config-file> <testcase-length> <# testcases>
---

# Split the generated testsuite on archive host
util-split-dir.sh <testsuite-path> <number of partitions>

# Distribute testcases on cluster
cluster-tc-dist.sh <aut-name> <host-config-file> <archive-username> <archive-hostname> <archive-auts-dir> <testsuite-name>

# Replay testcases
cluster-replay.sh <aut-name> <host-config-file> <archive-username> <archive-hostlist> <archive-auts-dir> <testsuite-name>


#----------------------
# Legend
#----------------------
<archive-username> = Username on hosts(s) where result of replaying testcases will be stored.

<archive-hostlist> = ':' separated list of archive hosts. Results will be archived to the first host. Rest are temporary stores.

<archive-auts-dir> = The "auts/" level directory on the archive host(s). The archived results will follow the directory layout of the Maryland dozen, starting from the "auts/" level.

#----------------------
# Figure
#
# This Figure shows the directory structure starting
# at the "guitar" repository level.
#----------------------
guitar/dozen/auts/ArgoUML/testsuites/sq_l_2/testcases
 |      |     |     |      |          |
 |      |     |     |      |          |
 |      |     |     |      |          + "testsuite" level. Also "testsuite name"
 |      |     |     |      + "testsuites/" level
 |      |     |     +-- "AUT Name" level
 |      |     +-- "auts/" level
 |      +-- Maryland "dozen" level
 +-- GUITAR repository level
