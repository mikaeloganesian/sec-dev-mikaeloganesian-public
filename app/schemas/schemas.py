from pydantic import BaseModel, Field, constr


class MovieBase(BaseModel):
    title: constr(min_length=1, max_length=100)

    year: int = Field(gt=1888, lt=2100)

    genre: constr(min_length=3, max_length=50, regex=r"^[a-zA-Z0-9\s-]*$")


class MovieCreate(MovieBase):
    pass


class MovieOut(MovieBase):
    id: int

    class Config:
        orm_mode = True


class CourseBase(BaseModel):
    title: constr(min_length=1, max_length=100)
    platform: constr(min_length=2, max_length=50, regex=r"^[a-zA-Z0-9\s-]*$")

    duration_hours: int = Field(gt=0, lt=1000)


class CourseCreate(CourseBase):
    pass


class CourseOut(CourseBase):
    id: int

    class Config:
        orm_mode = True
