class SaleOffer {
  String name;
  String image;
  String description;
  SaleOffer(
      {required this.name, required this.image, required this.description});
}

List<SaleOffer> saleOffers = [
  SaleOffer(
    name: "Winter Sale",
    image: "assets/images/sale_offers/1.png",
    description: "10% off on all orders",
  ),
  SaleOffer(
    name: "Friday Sale",
    image: "assets/images/sale_offers/2.png",
    description: "15% off on all orders",
  ),
  SaleOffer(
    name: "Summer Sale",
    image: "assets/images/sale_offers/3.png",
    description: "20% off on all T-Shirts",
  )
];
