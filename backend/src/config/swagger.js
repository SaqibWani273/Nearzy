const swaggerJsdoc = require('swagger-jsdoc');

const serverUrl = process.env.HOST_URL || 'http://localhost:8080/';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Nearzy API',
      description: `**Nearzy** is a hyper-local e-commerce marketplace REST API.

## Overview
- **Shops** register, get verified, and list products with multiple images and colors
- **Customers** browse products, manage multi-address profiles, manage shopping carts, write reviews, and place orders
- **Admins** manage hierarchical product categories and verify shops

## Authentication
All authenticated endpoints require a **JWT Bearer token** obtained via the login endpoints.
Include it in the \`Authorization\` header as \`Bearer <token>\`.

## Roles
| Role | Description |
|------|-------------|
| \`ROLE_CUSTOMER\` | Registered customer — can browse, manage cart, add addresses, write reviews, and order |
| \`ROLE_SHOP_OWNER\` / \`ROLE_SHOP\` | Registered shop owner — can list and manage products, images, and shop profile |
| \`ROLE_ADMIN\` | Platform administrator — manages categories and verifies shops |`,
      version: '2.0.0',
      contact: {
        name: 'Saqib Wani',
        email: 'saqibwani273@gmail.com',
        url: 'https://github.com/SaqibWani273',
      },
      license: {
        name: 'MIT License',
        url: 'https://opensource.org/licenses/MIT',
      },
    },
    servers: [
      {
        url: serverUrl,
        description: 'Current Server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter your JWT token obtained from the login endpoint',
        },
      },
    },
    tags: [
      { name: 'Health', description: 'Server health and status monitoring' },
      { name: 'Customer Auth', description: 'Customer registration, email verification, and login' },
      { name: 'Shop Auth', description: 'Shop registration, email verification, and login' },
      { name: 'Admin Auth', description: 'Admin registration, email verification, and login' },
      { name: 'Customer', description: 'Customer profile, cart management, and product browsing' },
      { name: 'Customer Payments', description: 'Razorpay order creation and payment verification' },
      { name: 'Shop', description: 'Shop profile and product management' },
      { name: 'Admin', description: 'Platform administration — categories and oversight' },
      { name: 'Common', description: 'Shared endpoints for all authenticated users' },
    ],
  },
  apis: ['./src/routes/*.js'],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
