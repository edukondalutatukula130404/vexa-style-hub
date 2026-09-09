const Item = require('../models/Item');

const defaultItems = [
  {
    _id: '101',
    name: 'Emerald Acid Wash Boxy Tee',
    description: '240 GSM heavyweight cotton with custom emerald acid wash texture and drop-shoulder silhouette.',
    price: 1899,
    category: 'Limited',
    collectionType: 'Oversized 240 GSM',
    image: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=800&auto=format&fit=crop&q=80',
    inStock: true
  },
  {
    _id: '102',
    name: 'Lavender Lilac Drop-Shoulder Tee',
    description: '240 GSM combed cotton in pastel lilac tone with luxury heavy rib collar.',
    price: 1699,
    category: 'Oversized',
    collectionType: 'Oversized 240 GSM',
    image: 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800&auto=format&fit=crop&q=80',
    inStock: true
  },
  {
    _id: '103',
    name: 'Gold-Embroidered Luxe Tee',
    description: 'High-density 240 GSM luxury cream cotton featuring metallic gold chest embroidery.',
    price: 1799,
    category: 'Limited',
    collectionType: 'Limited Edition',
    image: 'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=800&auto=format&fit=crop&q=80',
    inStock: true
  },
  {
    _id: '104',
    name: 'Vintage Rust Heavyweight Tee',
    description: 'Heavyweight vintage rust vintage-wash finish, boxy oversized drop-shoulder cut.',
    price: 1699,
    category: 'Oversized',
    collectionType: 'Explore Collections',
    image: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=800&auto=format&fit=crop&q=80',
    inStock: true
  },
  {
    _id: '105',
    name: 'Obsidian Stealth Oversized Tee',
    description: 'Deep obsidian black 240 GSM pre-shrunk cotton with subtle tone-on-tone silicone branding.',
    price: 1499,
    category: 'Oversized',
    collectionType: 'Explore Collections',
    image: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800&auto=format&fit=crop&q=80',
    inStock: true
  }
];

// @desc    Get all items
// @route   GET /api/items
// @access  Public
exports.getItems = async (req, res, next) => {
  try {
    const items = await Item.find();
    res.status(200).json({
      success: true,
      count: items.length,
      data: items
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

// @desc    Seed initial items if DB empty
exports.seedItems = async () => {
  try {
    const count = await Item.countDocuments();
    if (count === 0) {
      console.log('📦 Seeding initial VEXA Heavyweight T-Shirt collection items...');
      const defaultItems = [
        {
          name: 'Emerald Acid Wash Boxy Tee',
          description: '240 GSM heavyweight cotton with custom emerald acid wash texture and drop-shoulder silhouette.',
          price: 1899,
          category: 'Limited',
          collectionType: 'Oversized 240 GSM',
          image: '',
          inStock: true
        },
        {
          name: 'Lavender Lilac Drop-Shoulder Tee',
          description: '240 GSM combed cotton in pastel lilac tone with luxury heavy rib collar.',
          price: 1699,
          category: 'Oversized',
          collectionType: 'Oversized 240 GSM',
          image: '',
          inStock: true
        },
        {
          name: 'Gold-Embroidered Luxe Tee',
          description: 'High-density 240 GSM luxury cream cotton featuring metallic gold chest embroidery.',
          price: 1799,
          category: 'Limited',
          collectionType: 'Limited Edition',
          image: '',
          inStock: true
        },
        {
          name: 'Vintage Rust Heavyweight Tee',
          description: 'Heavyweight vintage rust vintage-wash finish, boxy oversized drop-shoulder cut.',
          price: 1699,
          category: 'Oversized',
          collectionType: 'Explore Collections',
          image: '',
          inStock: true
        },
        {
          name: 'Obsidian Stealth Oversized Tee',
          description: 'Deep obsidian black 240 GSM pre-shrunk cotton with subtle tone-on-tone silicone branding.',
          price: 1499,
          category: 'Oversized',
          collectionType: 'Explore Collections',
          image: '',
          inStock: true
        }
      ];
      await Item.insertMany(defaultItems);
      console.log('✅ Default VEXA items seeded successfully into database');
    }
  } catch (err) {
    console.error('Error seeding items:', err.message);
  }
};
