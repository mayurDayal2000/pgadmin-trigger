from sqlalchemy.orm import Session
from app.crud.base import CRUDBase
from app.models import Product, Order, OrderItem
from app.schemas.order import OrderCreate, OrderUpdate

class CRUDOrder(CRUDBase[Order, OrderCreate, OrderUpdate]):
    def create_with_items(self, db: Session, *, obj_in: OrderCreate) -> Order:
        # Create the Order first
        order_data = obj_in.dict(exclude={'items'})
        db_order = Order(**order_data, total_amount=0) # Placeholder total
        db.add(db_order)
        db.commit()
        db.refresh(db_order)

        total_amount = 0
        for item_in in obj_in.items:
            product = db.query(Product).filter(Product.id == item_in.product_id).first()
            if not product or product.stock_quantity < item_in.quantity:
                # Rollback order creation if any product is invalid or out of stock
                db.delete(db_order)
                db.commit()
                raise ValueError(f"Product ID {item_in.product_id} is out of stock or does not exist.")
            
            # Create OrderItem
            db_item = OrderItem(
                order_id=db_order.id,
                product_id=item_in.product_id,
                quantity=item_in.quantity,
                unit_price=product.price
            )
            db.add(db_item)
            
            # Update product stock
            product.stock_quantity -= item_in.quantity
            db.add(product)
            
            total_amount += item_in.quantity * product.price

        # Update order's total amount
        db_order.total_amount = total_amount
        db.add(db_order)
        db.commit()
        db.refresh(db_order)
        return db_order

order = CRUDOrder(Order)