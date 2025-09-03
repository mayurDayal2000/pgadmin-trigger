from sqlalchemy import Column, Integer, String, Float, DateTime, func
from app.database.base import Base

class Product(Base):
    __tablename__ = "products"  # <-- ADD THIS LINE

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String, nullable=True)
    price = Column(Float, nullable=False)
    stock_quantity = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())