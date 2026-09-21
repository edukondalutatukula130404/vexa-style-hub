const Item = require('../models/Item');

const defaultItems = [
  {
    _id: 'vx-08',
    name: 'Emerald Acid Wash Boxy Tee',
    description: '240 GSM heavyweight cotton with custom emerald acid wash texture and drop-shoulder silhouette.',
    price: 1899,
    oldPrice: 2699,
    category: 'Limited',
    collectionType: 'New Arrivals',
    image: 'assets/images/tee-emerald.png',
    inStock: true
  },
  {
    _id: 'vx-12',
    name: 'Lavender Lilac Drop-Shoulder Tee',
    description: '240 GSM combed cotton in pastel lilac tone with luxury heavy rib collar.',
    price: 1699,
    oldPrice: 2399,
    category: 'Oversized',
    collectionType: 'New Arrivals',
    image: 'assets/images/tee-lavender.png',
    inStock: true
  },
  {
    _id: 'vx-00',
    name: 'Gold-Embroidered Luxe Tee',
    description: 'High-density 240 GSM luxury cream cotton featuring metallic gold chest embroidery.',
    price: 1799,
    oldPrice: 2499,
    category: 'Limited',
    collectionType: 'Featured',
    image: 'assets/images/hero_luxury_tshirt.png',
    inStock: true
  },
  {
    _id: 'vx-07',
    name: 'Vintage Rust Heavyweight Tee',
    description: 'Heavyweight vintage rust vintage-wash finish, boxy oversized drop-shoulder cut.',
    price: 1699,
    oldPrice: 2399,
    category: 'Oversized',
    collectionType: 'New Arrivals',
    image: 'assets/images/tee-rust.png',
    inStock: true
  },
  {
    _id: 'vx-01',
    name: 'Obsidian Stealth Oversized Tee',
    description: 'Deep obsidian black 240 GSM pre-shrunk cotton with subtle tone-on-tone silicone branding.',
    price: 1499,
    oldPrice: 2199,
    category: 'Oversized',
    collectionType: 'Featured',
    image: 'assets/images/tee-black.jpg',
    inStock: true
  },
  {
    _id: 'vx-02',
    name: 'Ivory Signature Drop-Shoulder Tee',
    description: 'Classic ivory white 240 GSM drop-shoulder silhouette with signature rib collar.',
    price: 1399,
    oldPrice: 1999,
    category: 'Classic',
    collectionType: 'Featured',
    image: 'assets/images/tee-white.jpg',
    inStock: true
  },
  {
    _id: 'vx-03',
    name: 'Midnight Indigo Heavyweight Tee',
    description: 'Rich midnight navy 240 GSM heavyweight tee with double-stitched collar.',
    price: 1599,
    oldPrice: 2299,
    category: 'Oversized',
    collectionType: 'Featured',
    image: 'assets/images/tee-navy.jpg',
    inStock: true
  },
  {
    _id: 'vx-04',
    name: 'Desert Sand Minimalist Tee',
    description: 'Clean desert sand 240 GSM minimalist silhouette, bio-washed for lasting softness.',
    price: 1549,
    oldPrice: 2149,
    category: 'Limited',
    collectionType: 'New Arrivals',
    image: 'assets/images/tee-beige.jpg',
    inStock: true
  },
  {
    _id: 'vx-05',
    name: 'Charcoal Luxe Distressed Tee',
    description: 'Charcoal grey 240 GSM distressed-finish luxury tee with relaxed boxy cut.',
    price: 1449,
    oldPrice: 2099,
    category: 'Classic',
    collectionType: 'Featured',
    image: 'assets/images/tee-charcoal.jpg',
    inStock: true
  },
  {
    _id: 'vx-06',
    name: 'Olive Military Heritage Tee',
    description: 'Military olive 240 GSM heritage tee with garment-washed finish and relaxed oversized fit.',
    price: 1649,
    oldPrice: 2399,
    category: 'Limited',
    collectionType: 'New Arrivals',
    image: 'assets/images/tee-olive.jpg',
    inStock: true
  }
];

// @desc    Get all items
// @route   GET /api/items
// @access  Public
exports.getItems = async (req, res, next) => {
  try {
    const dbItems = await Item.find();
    
    // Official 10 mobile app products ALWAYS take top priority
    const defaultIds = new Set(defaultItems.map(i => i._id.toLowerCase()));
    const defaultNames = new Set(defaultItems.map(i => i.name.toLowerCase().trim()));

    // Filter out old legacy seed or duplicate items from MongoDB that conflict with mobile app products
    const extraCustomDbItems = dbItems.filter(i => {
      const id = (i._id || i.id || '').toString().toLowerCase().trim();
      const name = (i.name || '').toLowerCase().trim();
      if (name.includes('emerald silk')) return false;
      return !defaultIds.has(id) && !defaultNames.has(name);
    });

    const finalItems = [...defaultItems, ...extraCustomDbItems];

    return res.status(200).json({
      success: true,
      count: finalItems.length,
      data: finalItems
    });
  } catch (error) {
    res.status(200).json({
      success: true,
      count: defaultItems.length,
      data: defaultItems
    });
  }
};

// @desc    Create new item
// @route   POST /api/items
// @access  Public
exports.createItem = async (req, res, next) => {
  try {
    const item = await Item.create(req.body);
    res.status(201).json({
      success: true,
      data: item
    });
  } catch (error) {
    const newItem = { _id: Date.now().toString(), ...req.body };
    defaultItems.unshift(newItem);
    res.status(201).json({
      success: true,
      data: newItem
    });
  }
};

// @desc    Get single item
// @route   GET /api/items/:id
// @access  Public
exports.getItemById = async (req, res, next) => {
  try {
    const item = await Item.findById(req.params.id);
    if (!item) {
      const mockItem = defaultItems.find(i => i._id === req.params.id) || defaultItems[0];
      return res.status(200).json({ success: true, data: mockItem });
    }
    res.status(200).json({
      success: true,
      data: item
    });
  } catch (error) {
    const mockItem = defaultItems.find(i => i._id === req.params.id) || defaultItems[0];
    res.status(200).json({
      success: true,
      data: mockItem
    });
  }
};


// @desc    Update item
// @route   PUT /api/items/:id
// @access  Public
exports.updateItem = async (req, res, next) => {
  try {
    const item = await Item.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });
    if (!item) {
      return res.status(404).json({ success: false, message: 'Item not found' });
    }
    res.status(200).json({
      success: true,
      data: item
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete item
// @route   DELETE /api/items/:id
// @access  Public
exports.deleteItem = async (req, res, next) => {
  try {
    const item = await Item.findByIdAndDelete(req.params.id);
    if (!item) {
      return res.status(404).json({ success: false, message: 'Item not found' });
    }
    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Seed initial items if DB empty or update unsplash images
exports.seedItems = async () => {
  try {
    const seedData = [
      {
        _id: 'vx-08',
        name: 'Emerald Acid Wash Boxy Tee',
        description: '240 GSM heavyweight cotton with custom emerald acid wash texture and drop-shoulder silhouette.',
        price: 1899,
        oldPrice: 2699,
        category: 'Limited',
        collectionType: 'New Arrivals',
        image: 'assets/images/tee-emerald.png',
        inStock: true
      },
      {
        _id: 'vx-12',
        name: 'Lavender Lilac Drop-Shoulder Tee',
        description: '240 GSM combed cotton in pastel lilac tone with luxury heavy rib collar.',
        price: 1699,
        oldPrice: 2399,
        category: 'Oversized',
        collectionType: 'New Arrivals',
        image: 'assets/images/tee-lavender.png',
        inStock: true
      },
      {
        _id: 'vx-00',
        name: 'Gold-Embroidered Luxe Tee',
        description: 'High-density 240 GSM luxury cream cotton featuring metallic gold chest embroidery.',
        price: 1799,
        oldPrice: 2499,
        category: 'Limited',
        collectionType: 'Featured',
        image: 'assets/images/hero_luxury_tshirt.png',
        inStock: true
      },
      {
        _id: 'vx-07',
        name: 'Vintage Rust Heavyweight Tee',
        description: 'Heavyweight vintage rust vintage-wash finish, boxy oversized drop-shoulder cut.',
        price: 1699,
        oldPrice: 2399,
        category: 'Oversized',
        collectionType: 'New Arrivals',
        image: 'assets/images/tee-rust.png',
        inStock: true
      },
      {
        _id: 'vx-01',
        name: 'Obsidian Stealth Oversized Tee',
        description: 'Deep obsidian black 240 GSM pre-shrunk cotton with subtle tone-on-tone silicone branding.',
        price: 1499,
        oldPrice: 2199,
        category: 'Oversized',
        collectionType: 'Featured',
        image: 'assets/images/tee-black.jpg',
        inStock: true
      },
      {
        _id: 'vx-02',
        name: 'Ivory Signature Drop-Shoulder Tee',
        description: 'Classic ivory white 240 GSM drop-shoulder silhouette with signature rib collar.',
        price: 1399,
        oldPrice: 1999,
        category: 'Classic',
        collectionType: 'Featured',
        image: 'assets/images/tee-white.jpg',
        inStock: true
      },
      {
        _id: 'vx-03',
        name: 'Midnight Indigo Heavyweight Tee',
        description: 'Rich midnight navy 240 GSM heavyweight tee with double-stitched collar.',
        price: 1599,
        oldPrice: 2299,
        category: 'Oversized',
        collectionType: 'Featured',
        image: 'assets/images/tee-navy.jpg',
        inStock: true
      },
      {
        _id: 'vx-04',
        name: 'Desert Sand Minimalist Tee',
        description: 'Clean desert sand 240 GSM minimalist silhouette, bio-washed for lasting softness.',
        price: 1549,
        oldPrice: 2149,
        category: 'Limited',
        collectionType: 'New Arrivals',
        image: 'assets/images/tee-beige.jpg',
        inStock: true
      },
      {
        _id: 'vx-05',
        name: 'Charcoal Luxe Distressed Tee',
        description: 'Charcoal grey 240 GSM distressed-finish luxury tee with relaxed boxy cut.',
        price: 1449,
        oldPrice: 2099,
        category: 'Classic',
        collectionType: 'Featured',
        image: 'assets/images/tee-charcoal.jpg',
        inStock: true
      },
      {
        _id: 'vx-06',
        name: 'Olive Military Heritage Tee',
        description: 'Military olive 240 GSM heritage tee with garment-washed finish and relaxed oversized fit.',
        price: 1649,
        oldPrice: 2399,
        category: 'Limited',
        collectionType: 'New Arrivals',
        image: 'assets/images/tee-olive.jpg',
        inStock: true
      }
    ];

    const count = await Item.countDocuments();
    if (count === 0) {
      console.log('📦 Seeding initial VEXA Heavyweight T-Shirt collection items...');
      await Item.insertMany(seedData);
      console.log('✅ Default VEXA items seeded successfully into database');
    } else {
      // Update any items with unsplash images to use clean asset paths
      await Item.updateMany(
        { image: { $regex: 'unsplash.com', $options: 'i' } },
        { $set: { image: 'assets/images/tee-emerald.png' } }
      );
    }
  } catch (err) {
    console.error('Error seeding items:', err.message);
  }
};
