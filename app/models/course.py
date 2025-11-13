from sqlalchemy import Column, Integer, String

from ..db.database import Base


class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    platform = Column(String)
    duration_hours = Column(Integer)
