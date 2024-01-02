library spi2axi

include TestHarness.pro

analyze  tb_spi2axi_operation2.vhd

simulate tb_spi2axi_operation2 [generic SPI_CPOL 0] [generic SPI_CPHA 0]
