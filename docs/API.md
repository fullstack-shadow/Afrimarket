# API Documentation

## REST API Endpoints

### Authentication

`POST /api/auth/login`

- Request: `{ email: string, password: string }`
- Response: `{ token: string, user: User }`

### Products

`GET /api/products`

- Query Params: `?sellerId=string&category=string`
- Response: `Product[]`

`POST /api/products`

- Headers: `Authorization: Bearer <seller-token>`
- Request: `Product`
- Response: `{ id: string }`

## GraphQL Schema

```graphql
type Product {
  id: ID!
  name: String!
  price: Float!
  seller: User!
  images: [String!]!
}

type Query {
  products(sellerId: ID): [Product!]!
}
```
