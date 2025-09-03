from pydantic import BaseModel
from .product import Product

class OrderItemBase(BaseModel):
    product_id: int
    quantity: int

class OrderItemCreate(OrderItemBase):
    pass

class OrderItem(OrderItemBase):
    id: int
    unit_price: float

    class Config:
        orm_mode = True

class OrderItemWithProduct(OrderItem):
    product: Product