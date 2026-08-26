const swaggerJsdoc = require('swagger-jsdoc');

const serverUrl = process.env.HOST_URL || 'http://localhost:8080/';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Localezy API',
      description: `**Localezy** is a local e-commerce marketplace REST API.

## Overview
- **Shops** register, get verified, and list products for sale
- **Customers** browse products, manage shopping carts, and place orders
- **Admins** manage product categories and oversee the platform

## Authentication
All authenticated endpoints require a **JWT Bearer token** obtained via the login endpoints.
Include it in the \`Authorization\` header as \`Bearer <token>\`.

## Roles
| Role | Description |
|------|-------------|
| \`ROLE_CUSTOMER\` | Registered customer — can browse, cart, and purchase |
| \`ROLE_SHOP\` | Registered shop owner — can list and manage products |
| \`ROLE_ADMIN\` | Platform administrator — manages categories and shops |`,
      version: '1.0.0',
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
      { name: 'Shop', description: 'Shop profile and product management' },
      { name: 'Admin', description: 'Platform administration — categories and oversight' },
      { name: 'Common', description: 'Shared endpoints for all authenticated users' },
    ],
  },
  apis: ['./src/routes/*.js'],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
