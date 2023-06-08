from fastapi import FastAPI
import asyncio

app = FastAPI()


@app.get("/")
async def read_root():
    await asyncio.sleep(5)
    return {"Hello": "Worldfhasjdfhkajsfhdjkahsdfkjahfjkladflaliehliaufewhilhewlfiilawfhileawfliew"}


@app.get("/api/v1")
async def read_root():
    await asyncio.sleep(5)
    return {"API": "Worldfhasjdfhkajsfhdjkahsdfkjahfjkladflaliehliaufewhilhewlfiilawfhileawfliew"}
