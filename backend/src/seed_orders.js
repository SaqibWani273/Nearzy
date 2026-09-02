/**
 * seed_orders.js – Add sample orders to existing seeded data.
 */
require('dotenv').config();
const {
  sequelize, Customer, Address, Product, OrderRecord, OrderItem,
} = require('./models');

const rnd = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
const pick = (arr) => arr[rnd(0, arr.length - 1)];

async function seedOrders() {
  try {
    await sequelize.authenticate();

    const existing = await OrderRecord.count();
    if (existing > 0) {
      console.log('⚠️  Orders already exist. Skipping.');
      process.exit(0);
    }

    const customers = await Customer.findAll();
    const addresses = await Address.findAll();
    const products = await Product.findAll();

    const orderStatuses = ['PLACED', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'DELIVERED'];
    const paymentStatuses = ['PAID', 'PAID', 'PAID', 'PENDING'];

    let orderCount = 0;
    for (let i = 0; i < 8; i++) {
      const cust = customers[i % customers.length];
      const addr = addresses.find(a => String(a.customerId) === String(cust.id)) || addresses[0];
      const numItems = rnd(1, 3);
      const selected = [];
      for (let j = 0; j < numItems; j++) {
        selected.push(products[rnd(0, products.length - 1)]);
      }

      let totalPaise = 0;
      let totalDiscount = 0;
      const items = selected.map(p => {
        const qty = rnd(1, 2);
        const unitPrice = p.priceInPaise;
        const discPaise = Math.round(unitPrice * p.discountPercent / 100);
        totalPaise += unitPrice * qty;
        totalDiscount += discPaise * qty;
        return { product: p, qty, unitPrice, discPaise };
      });

      const orderNum = `NRZ-${Date.now()}-${String(i + 1).padStart(4, '0')}`;
      const order = await OrderRecord.create({
        customerId: cust.id,
        shippingAddressId: addr.id,
        orderNumber: orderNum,
        totalAmountPaise: totalPaise - totalDiscount,
        discountAmountPaise: totalDiscount,
        status: pick(orderStatuses),
        paymentStatus: pick(paymentStatuses),
      });

      for (const item of items) {
        await OrderItem.create({
          orderId: order.id,
          productId: item.product.id,
          shopId: item.product.shopId,
          quantity: item.qty,
          unitPricePaise: item.unitPrice,
          discountPaise: item.discPaise,
        });
      }
      orderCount++;
    }

    console.log(`📦 ${orderCount} orders created`);
    console.log('🎉 Done!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed:', err);
    process.exit(1);
  }
}

seedOrders();
