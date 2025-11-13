from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..db.database import get_db
from ..models.course import Course as CourseModel
from ..schemas.schemas import CourseCreate, CourseOut

router = APIRouter()


@router.get("/", response_model=list[CourseOut])
def read_courses(db: Session = Depends(get_db)):
    return db.query(CourseModel).all()


@router.get("/{course_id}", response_model=CourseOut)
def read_course(course_id: int, db: Session = Depends(get_db)):
    course = db.query(CourseModel).filter(CourseModel.id == course_id).first()
    if course is None:
        raise HTTPException(status_code=404, detail="Курс не найден")
    return course


@router.post("/", response_model=CourseOut, status_code=status.HTTP_201_CREATED)
def create_new_course(course: CourseCreate, db: Session = Depends(get_db)):
    db_course = CourseModel(**course.dict())
    db.add(db_course)
    db.commit()
    db.refresh(db_course)
    return db_course


@router.delete("/{course_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_existing_course(course_id: int, db: Session = Depends(get_db)):
    course = db.query(CourseModel).filter(CourseModel.id == course_id).first()
    if course is None:
        raise HTTPException(status_code=404, detail="Курс не найден")

    db.delete(course)
    db.commit()
    return
