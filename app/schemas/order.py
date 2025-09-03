from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from .user import User
from .order_item import OrderItem, OrderItemCreate, OrderItemWithProduct

class OrderBase(BaseModel):
    user_id: int

class OrderCreate(OrderBase):
    items: List[OrderItemCreate]

class OrderUpdate(BaseModel):
    status: Optional[str] = None

class Order(OrderBase):
    id: int
    total_amount: float
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    items: List[OrderItem] = []

    class Config:
        orm_mode = True

class OrderDetails(Order):
    user: User
    items: List[OrderItemWithProduct] = []