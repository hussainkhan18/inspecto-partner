import 'package:flutter/material.dart';
import 'package:techno_shield/helper/style.dart';
import 'package:techno_shield/models/user_model.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:provider/provider.dart';
import '/helper/style.dart' as style;
import 'package:techno_shield/view_models/cart_view_model.dart';

class ProductDetailPage extends StatefulWidget {
  final String itemImage;
  final String itemName;
  final String itemPrice;
  final int id;

  const ProductDetailPage({
    super.key,
    Title? title,
    required this.itemImage,
    required this.itemName,
    required this.id,
    required this.itemPrice,
  });
  final String title = '';

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: style.appColor),
        // actions: [
        //   IconButton(
        //       onPressed: () {}, icon: const Icon(Icons.favorite_outline)),
        //   IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined))
        // ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomContainer(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                    image: DecorationImage(
                  image: NetworkImage(widget.itemImage),
                  onError: (error, stackTrace) {
                    // Handle the error here
                    print('Error loading image: $error');
                  },
                ))),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: style.bottomBorder(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [],
                  ),
                  Text(
                    widget.itemName,
                    style:
                        const TextStyle(fontSize: 24, fontFamily: 'semi-bold'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'RS ${widget.itemPrice}',
                          style: const TextStyle(
                              fontSize: 24, fontFamily: 'semi-bold'),
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_quantity > 1) _quantity--;
                              });
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: btnBox(),
                              child: const Icon(Icons.remove,
                                  color: style.appColor),
                            ),
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                    fontSize: 16, fontFamily: 'semi-bold'),
                              )),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: btnBox(),
                              child:
                                  const Icon(Icons.add, color: style.appColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       _buildTitleLabel('Product Details'),
            //       const SizedBox(height: 16),
            //       const Text(
            //         'Lorem Ipsum is simply dummy text of the printing and typesetting '
            //         'industry. Lorem Ipsum has been the industry\'s standard dummy text '
            //         'ever since the 1500s, when an unknown printer took a galley of type '
            //         'and scrambled it to make a type specimen book.',
            //         style: TextStyle(fontSize: 13, color: Colors.grey),
            //       ),
            //       const SizedBox(height: 16),
            //       _buildTitleLabel('Maybe You Likes'),
            //       const SizedBox(height: 16),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleLabel(val) {
    return Text(
      '$val',
      style: const TextStyle(fontSize: 17, fontFamily: 'medium'),
    );
  }

  btnBox() {
    return BoxDecoration(
        border: Border.all(width: 2, color: style.appColor),
        borderRadius: const BorderRadius.all(Radius.circular(3)));
  }

  Widget _buildBottomContainer() {
    final cartViewModel = Provider.of<CartViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child:
            const Center(child: Text('Please log in to add items to the cart')),
      );
    }

    final userId = user.id;
    if (userId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: Text('Invalid user ID')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          cartViewModel.addItemWithQuantity(
            Item(
              name: widget.itemName,
              itemImg: widget.itemImage,
              salePrice: widget.itemPrice,
              id: widget.id,
            ),
            _quantity,
            userId,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.itemName} \nAdded to cart',
                    style: const TextStyle(fontFamily: 'medium'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.cartPage,
                      );
                    },
                    child: const Text(
                      "View cart",
                      style: TextStyle(
                          color: style.appColor,
                          fontSize: 16,
                          fontFamily: 'medium'),
                    ),
                  )
                ],
              ),
            ),
          );
        },
        style: style.simpleButton(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Center the content
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * .22,
            ),
            const Text('Add to cart'),
          ],
        ),
      ),
    );
  }
}
