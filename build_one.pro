TestSuite Spi2Axi

# SetCoverageSimulateEnable true

library spi2axi
# SetCoverageAnalyzeEnable true
analyze src/synchronizer.vhd
analyze src/spi2axi.vhd
# SetCoverageAnalyzeEnable false

include ./tb/build_one.pro

# SetCoverageSimulateEnable false
