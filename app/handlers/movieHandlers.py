from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..db.database import get_db
from ..models.movie import Movie as MovieModel
from ..schemas.schemas import MovieCreate, MovieOut

router = APIRouter()


@router.get("/", response_model=list[MovieOut])
def read_movies(db: Session = Depends(get_db)):
    return db.query(MovieModel).all()


@router.get("/{movie_id}", response_model=MovieOut)
def read_movie(movie_id: int, db: Session = Depends(get_db)):
    movie = db.query(MovieModel).filter(MovieModel.id == movie_id).first()
    if movie is None:
        raise HTTPException(status_code=404, detail="Фильм не найден")
    return movie


@router.post("/", response_model=MovieOut, status_code=status.HTTP_201_CREATED)
def create_new_movie(movie: MovieCreate, db: Session = Depends(get_db)):
    db_movie = MovieModel(**movie.dict())
    db.add(db_movie)
    db.commit()
    db.refresh(db_movie)
    return db_movie


@router.delete("/{movie_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_existing_movie(movie_id: int, db: Session = Depends(get_db)):
    movie = db.query(MovieModel).filter(MovieModel.id == movie_id).first()
    if movie is None:
        raise HTTPException(status_code=404, detail="Фильм не найден")

    db.delete(movie)
    db.commit()
    return
