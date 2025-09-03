import asyncio
from app.database.session import SessionLocal
from app.models.user import User
from app.models.product import Product

async def seed_data():
    db = SessionLocal()
    try:
        # Check if data already exists
        if db.query(User).first() or db.query(Product).first():
            print("Data already exists. Skipping seed.")
            return

        print("Seeding initial data...")

        # Create Users
        user1 = User(name="Alice Johnson", email="alice@example.com")
        user2 = User(name="Bob Smith", email="bob@example.com")
        db.add_all([user1, user2])
        db.commit()

        # Create Products
        product1 = Product(name="Laptop Pro", description="A powerful laptop", price=1200.00, stock_quantity=50)
        product2 = Product(name="Smartphone X", description="The latest smartphone", price=800.00, stock_quantity=150)
        product3 = Product(name="Wireless Headphones", description="High-quality sound", price=150.00, stock_quantity=200)
        db.add_all([product1, product2, product3])
        db.commit()

        print("Seeding completed successfully.")

    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(seed_data())