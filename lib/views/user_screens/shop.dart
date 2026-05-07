import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:techno_shield/helper/style.dart';
import 'package:techno_shield/models/user_model.dart'; // Import the BannerItem class from user_model.dart
import 'package:techno_shield/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:techno_shield/view_models/cart_view_model.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '/helper/style.dart' as style;

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  static const String page_id = 'Shop';

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late Future<List<Item>> futureProducts;
  late Future<List<BannerItem>> futureBanners;

  @override
  void initState() {
    super.initState();
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;
    futureProducts = userViewModel.fetchProducts(user?.referralCode ?? '');
    futureBanners = userViewModel.fetchBanners(user?.referralCode ?? '');
    if (kDebugMode) {
      print("USER REFEREL CODE ${user?.referralCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final user = userViewModel.currentUser;
    print("comapny image${user?.companyImg}");

    if (user == null) {
      return const Center(child: Text('No user data available'));
    }
    print(user.companyImg);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: Image.network(
                '${user.companyImg}', // Replace with your image URL
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  }
                },
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return const Text('Failed to load image');
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Welcome to ${user.companyName}',
              style: const TextStyle(
                  fontSize: 14, fontFamily: 'semi-bold', color: Colors.black),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //       onPressed: () {},
        //       icon: const Icon(Icons.notifications_none, color: Colors.grey)),
        //   IconButton(
        //       onPressed: () {},
        //       icon: const Icon(Icons.local_offer_outlined, color: Colors.grey))
        // ],
      ),
      body: _buildBody(user),
    );
  }

  Widget _buildBody(User? user) {
    if (user == null) {
      return const Center(child: Text('No user data available'));
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 10),
            child: Card(
              color: Colors.white,
              child: TextField(
                decoration: searchBox(),
              ),
            ),
          ),
          _buildSlider(),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Products',
                  style: TextStyle(fontSize: 18, fontFamily: 'medium'),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Item>>(
                  future: futureProducts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      if (kDebugMode) {
                        print('Error: ${snapshot.error}');
                      }
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No products available'));
                    } else {
                      final products = snapshot.data!;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const ScrollPhysics(),
                        mainAxisSpacing: 5,
                        crossAxisSpacing: 5,
                        childAspectRatio: 90 / 100,
                        children: List.generate(products.length, (index) {
                          return _buildSingleProduct(products[index]);
                        }),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration searchBox() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintText: 'Search for products',
      filled: true,
      fillColor: Colors.white,
      border: searchBorder(),
      focusedBorder: searchBorder(),
      enabledBorder: searchBorder(),
    );
  }

  OutlineInputBorder searchBorder() {
    return const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide:
            BorderSide(color: Color.fromARGB(255, 224, 239, 250), width: 1));
  }

  List<BannerItem> localBanners = [
    BannerItem(name: 'Avocado 5% OFF', banner_img: 'assets/images/avocado.png'),
    BannerItem(
        name: 'Free delivery every purchase',
        banner_img: 'assets/images/grapes.png'),
    BannerItem(
        name: 'Free lettuce on every purchase',
        banner_img: 'assets/images/kale.png'),
    BannerItem(name: '12% OFF on Mango', banner_img: 'assets/images/mango.png'),
  ];

  Widget _buildSlider() {
    return FutureBuilder<List<BannerItem>>(
      future: futureBanners,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          if (kDebugMode) {
            print('Error: ${snapshot.error}');
          }
          return _buildLocalBannerSlider(localBanners);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildLocalBannerSlider(localBanners);
        } else {
          final banners = snapshot.data!;
          return _buildNetworkBannerSlider(banners);
        }
      },
    );
  }

  Widget _buildNetworkBannerSlider(List<BannerItem> banners) {
    return SizedBox(
      width: double.infinity,
      height: 210,
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          enlargeCenterPage: true, // This will make the center item bigger
          viewportFraction: 0.9, // Adjust the fraction to make it look nicer
          enlargeStrategy: CenterPageEnlargeStrategy.height,
        ),
        items: banners.map((banner) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15), // Circular border radius
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(15), // Clip image to circular borders
              child: Image.network(
                banner.banner_img,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover, // Cover the entire area
                errorBuilder: (context, error, stackTrace) {
                  if (kDebugMode) {
                    print('Error loading image: $error');
                  }
                  return const Icon(Icons.error); // Display an error icon
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Widget _buildNetworkBannerSlider(List<BannerItem> banners) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 210,
  //     child: CarouselSlider(
  //       options: CarouselOptions(
  //         autoPlay: true,
  //         enlargeCenterPage: false,
  //         viewportFraction: 0.95,
  //         enlargeStrategy: CenterPageEnlargeStrategy.height,
  //       ),
  //       items: banners.map((banner) {
  //         return Card(
  //           // width: double.infinity,
  //           margin: const EdgeInsets.symmetric(horizontal: 8),
  //           // height: 230,
  //           // padding: const EdgeInsets.only(left: 15),
  //           // decoration: const BoxDecoration(
  //           //   borderRadius: BorderRadius.all(Radius.circular(5)),
  //           color: Colors.blue[50], // Change the color as needed
  //           // ),
  //           child: Padding(
  //             padding: const EdgeInsets.only(left: 0),
  //             child:
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 // Expanded(
  //                 //   child: Column(
  //                 //     crossAxisAlignment: CrossAxisAlignment.start,
  //                 //     mainAxisAlignment: MainAxisAlignment.center,
  //                 //     children: [
  //                 //       Text(
  //                 //         banner.name.toUpperCase(),
  //                 //         style: const TextStyle(
  //                 //           color: appColor,
  //                 //           fontSize: 18,
  //                 //           fontFamily: 'medium',
  //                 //         ),
  //                 //       ),
  //                 //       Container(
  //                 //         width: 150,
  //                 //         margin: const EdgeInsets.only(top: 16),
  //                 //         child: _buildCheckBtn(),
  //                 //       ),
  //                 //     ],
  //                 //   ),
  //                 // ),

  //                 SizedBox(
  //                   height: 230,
  //                   width: 180,
  //                   child: Image.network(
  //                     banner.banner_img,
  //                     // fit: BoxFit.cover,
  //                     errorBuilder: (context, error, stackTrace) {
  //                       if (kDebugMode) {
  //                         print('Error loading image: $error');
  //                       }
  //                       return const Icon(Icons.error); // Display an error icon
  //                     },
  //                     loadingBuilder: (context, child, loadingProgress) {
  //                       if (loadingProgress == null) return child;
  //                       return Center(
  //                         child: CircularProgressIndicator(
  //                           value: loadingProgress.expectedTotalBytes != null
  //                               ? loadingProgress.cumulativeBytesLoaded /
  //                                   loadingProgress.expectedTotalBytes!
  //                               : null,
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             // Stack(
  //             //   children: [
  //             //     SizedBox(
  //             //                       height: 250,
  //             //                       width: 320,
  //             //                       child: Image.network(
  //             //                         banner.banner_img,
  //             //                         // fit: BoxFit.cover,
  //             //                         errorBuilder: (context, error, stackTrace) {
  //             //                           if (kDebugMode) {
  //             //                             print('Error loading image: $error');
  //             //                           }
  //             //                           return const Icon(Icons.error); // Display an error icon
  //             //                         },
  //             //                         loadingBuilder: (context, child, loadingProgress) {
  //             //                           if (loadingProgress == null) return child;
  //             //                           return Center(
  //             //                             child: CircularProgressIndicator(
  //             //      value: loadingProgress.expectedTotalBytes != null
  //             //          ? loadingProgress.cumulativeBytesLoaded /
  //             //              loadingProgress.expectedTotalBytes!
  //             //          : null,
  //             //                             ),
  //             //                           );
  //             //                         },
  //             //                       ),
  //             //                ),

  //             //     //                       Text(
  //             //     //                         banner.name.toUpperCase(),
  //             //     //                         style: const TextStyle(
  //             //     //  color: appColor,
  //             //     //  fontSize: 18,
  //             //     //  fontFamily: 'medium',
  //             //     //                         ),
  //             //     //                       ),
  //             //                           // Padding(
  //             //                           //   padding: const EdgeInsets.only(left: 150,top: 140),
  //             //                           //   child: Container(
  //             //                           //     width: 150,
  //             //                           //     margin: const EdgeInsets.only(top: 16),
  //             //                           //     child: _buildCheckBtn(),
  //             //                           //   ),
  //             //                           // ),

  //             //   ],
  //             // ),
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  Widget _buildLocalBannerSlider(List<BannerItem> localBanners) {
    return SizedBox(
      width: double.infinity,
      height: 230,
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          enlargeCenterPage: false,
          viewportFraction: 0.9,
          enlargeStrategy: CenterPageEnlargeStrategy.height,
        ),
        items: localBanners.map((banner) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 230,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              color: Colors.grey, // Change the color as needed
            ),
            child: Center(
              child: SizedBox(
                height: 150,
                width: 150,
                child: Image.asset(
                  banner.banner_img,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckBtn() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: style.appColor,
          elevation: 0,
          textStyle: const TextStyle(fontFamily: 'medium')),
      child: Text('Explore'.toUpperCase()),
    );
  }

  Widget _buildSingleProduct(Item product) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.productDetailPage, // Use the route name from AppRoutes
          arguments: {
            'itemImage': product.itemImg,
            'itemName': product.name,
            'itemPrice': product.salePrice,
            'id': product.id,
          },
        );
      },
      child: Card(
        color: Colors.blue[50],
        // width: double.infinity,
        // height: 120,
        // padding: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.network(
                  product.itemImg,
                  height: 80,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                product.name,
                style: const TextStyle(fontSize: 13, fontFamily: 'medium'),
              ),
              Text(
                "Rs. ${product.salePrice}",
                style: const TextStyle(
                    fontSize: 13, color: appColor, fontFamily: 'medium'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
