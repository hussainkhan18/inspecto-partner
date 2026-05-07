    class User {
    int? id;
    String name;
    String address;
    // String location;
    String phoneNumber;
    String category;
    String idCardNo;
    String email;
    String? password;
    String? confirmPassword;
    String? referralCode;
    String zoneId;
    String? companyName;
    String? createdBy;
    String? companyImg;
    final String? latitude; // Add this field
    final String? longitude; // Add this field
      final String? profileImagePath; // Add this field to hold image path

    
    User(
        {this.id,
        required this.name,
        required this.address,
        // required this.location,
        required this.phoneNumber,
        required this.category,
        required this.idCardNo,
        required this.email,
        this.password,
        this.confirmPassword,
        this.referralCode,
        required this.zoneId,
        this.companyName,
        this.companyImg,
        this.createdBy,
        this.latitude,
        this.longitude,
            this.profileImagePath, // Initialize the image path
});

    factory User.fromJson(Map<String, dynamic> json) {
      return User(
        id: json['id'],
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        // location: json['location'] ?? '',
        phoneNumber: json['phone_number'] ?? '',
        category: json['category'] ?? '',
        idCardNo: json['id_card_no'] ?? '',
        email: json['email'] ?? '',
        password: json['password'],
        confirmPassword: json['confirm_password'],
        referralCode: json['refrel_code'],
        zoneId: json['zone_id'] ?? '',
        companyName: json['company_name'] ?? '',
        companyImg: json['company_img'] ?? '',
        createdBy: json['created_by'] ?? '',
        latitude: json['latitude'] ?? '',
        longitude: json['longitude'] ?? '',
       profileImagePath: json['profile_image'], // Add this




      );
    }

    Map<String, dynamic> toJson() {
      final data = {
        'id': id,
        'name': name,
        'address': address,
        // 'location': location,
        'phone_number': phoneNumber,
        'category': category,
        'id_card_no': idCardNo,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'refrel_code': referralCode,
        'zone_id': zoneId,

        'latitude': latitude,
        'longitude': longitude,
      };
      
      // Conditionally include company name and created by if they're not null
      if (companyName != null) {
        data['company_name'] = companyName;
      }
      if (companyImg != null) {
        data['company_img'] = companyImg;
      }
      if (createdBy != null) {
        data['created_by'] = createdBy;
      }
      
      return data;
    }
  }

class Item {
  final int? id;
  final String name;
  final String itemImg;
  final String salePrice;

  Item({
    this.id,
    required this.name,
    required this.itemImg,
    required this.salePrice,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      itemImg: json['item_img'],
      salePrice: json['sale_price'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Item && other.name == name && other.itemImg == itemImg;
  }

  @override
  int get hashCode => name.hashCode ^ itemImg.hashCode;
}

class BannerItem {
  final String name;
  final String banner_img;

  BannerItem({required this.name, required this.banner_img});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      name: json['name'] ?? 'Unknown',
      banner_img: json['banner_img'] ?? '',
    );
  }
}
