library spi2axi

include TestHarness.pro

analyze  tb_spi2axi_operation.vhd

simulate tb_spi2axi_operation [generic SPI_CPOL 0] [generic SPI_CPHA 0]
simulate tb_spi2axi_operation [generic SPI_CPOL 0] [generic SPI_CPHA 1]
simulate tb_spi2axi_operation [generic SPI_CPOL 1] [generic SPI_CPHA 0]
simulate tb_spi2axi_operation [generic SPI_CPOL 1] [generic SPI_CPHA 1]
                                                 ]
analyze  tb_spi2axi_overrun.vhd

simulate tb_spi2axi_overrun [generic SPI_CPOL 0] [generic SPI_CPHA 0]
simulate tb_spi2axi_overrun [generic SPI_CPOL 0] [generic SPI_CPHA 1]
simulate tb_spi2axi_overrun [generic SPI_CPOL 1] [generic SPI_CPHA 0]
simulate tb_spi2axi_overrun [generic SPI_CPOL 1] [generic SPI_CPHA 1]
