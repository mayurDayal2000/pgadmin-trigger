from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import crud, schemas
from app.api import deps

router = APIRouter()

@router.get("/", response_model=List[schemas.Order])
def read_orders(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 100):
    orders = crud.order.get_multi(db, skip=skip, limit=limit)
    return orders

@router.post("/", response_model=schemas.Order)
def create_order(*, db: Session = Depends(deps.get_db), order_in: schemas.OrderCreate):
    try:
        order = crud.order.create_with_items(db=db, obj_in=order_in)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return order

@router.get("/{order_id}", response_model=schemas.OrderDetails)
def read_order(*, db: Session = Depends(deps.get_db), order_id: int):
    order = crud.order.get(db=db, id=order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@router.put("/{order_id}", response_model=schemas.Order)
def update_order(*, db: Session = Depends(deps.get_db), order_id: int, order_in: schemas.OrderUpdate):
    order = crud.order.get(db=db, id=order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    order = crud.order.update(db=db, db_obj=order, obj_in=order_in)
    return order

@router.delete("/{order_id}", response_model=schemas.Order)
def delete_order(*, db: Session = Depends(deps.get_db), order_id: int):
    order = crud.order.get(db=db, id=order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    # Note: Deleting an order might require handling related items or stock adjustments.
    # This is a simple delete.
    order = crud.order.remove(db=db, id=order_id)
    return order