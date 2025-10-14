class HoseView {
  final int nozzleNumber;
  final String fullAddress;
  final int fuelCode;
  final double priceCash;
  final double priceCredit;
  final double priceDebit;
  final int priceDecimals;
  final int totalDecimals;
  final int volumeDecimals;
  final String status;

  HoseView({
    required this.nozzleNumber,
    required this.fullAddress,
    required this.fuelCode,
    required this.priceCash,
    required this.priceCredit,
    required this.priceDebit,
    required this.priceDecimals,
    required this.totalDecimals,
    required this.volumeDecimals,
    required this.status,
  });
}

