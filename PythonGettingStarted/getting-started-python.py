# %% [markdown]
# # Getting Started with Python
#
# Run each section using "Run Cell" in VS Code.

# %%
print("Hello, world!")

# %% [markdown]
# ## Variables

# %%
name = "John"
age = 30
print(name, age)

# %% [markdown]
# ## f-strings

# %%
print(f"Hello {name}")

# %% [markdown]
# ## Math

# %%
a = 10
b = 3
print(a + b, a * b)

# %% [markdown]
# ## Input

# %%
# Uncomment to try
# user = input("Name: ")
# print(f"Hi {user}")

# %% [markdown]
# ## Conditions

# %%
age = 20
if age >= 18:
    print("Adult")
else:
    print("Minor")

# %% [markdown]
# ## Loops

# %%
for i in range(5):
    print(i)

# %% [markdown]
# ## Lists

# %%
names = ["Alice", "Bob"]
for n in names:
    print(n)

# %% [markdown]
# ## Dictionaries

# %%
person = {"name": "John", "role": "Teacher"}
print(person["name"])

# %% [markdown]
# ## Functions

# %%
def greet(name):
    return f"Hello {name}"

print(greet("World"))

# %% [markdown]
# ## Mini Project (Task List)

# %%
tasks = []

tasks.append("Learn Python")
tasks.append("Build project")

for t in tasks:
    print(t)

# %% [markdown]
# ## Dictionaries

# %%
person = {
    "name": "John",
    "role": "Teacher",
    "topic": "Python"
}

print(person)
print(person["name"])
print(person["role"])
print(person["topic"])

# %% [markdown]
# ## Mini Project: Simple Task List

# %%
tasks = []

tasks.append("Learn Python")
tasks.append("Install VS Code")
tasks.append("Build first project")

print("My tasks:")
for index, task in enumerate(tasks, start=1):
    print(f"{index}. {task}")

# %% [markdown]
# ## Mini Project: Interactive Version

# %%
tasks = []

while True:
     print("\nSimple Task Tracker")
     print("1. Add task")
     print("2. View tasks")
     print("3. Exit")

     choice = input("Choose an option: ")

     if choice == "1":
         task = input("Enter a task: ")
         tasks.append(task)
         print("Task added.")

     elif choice == "2":
         if len(tasks) == 0:
             print("No tasks yet.")
         else:
             print("Your tasks:")
             for index, task in enumerate(tasks, start=1):
                 print(f"{index}. {task}")

     elif choice == "3":
         print("Goodbye!")
         break

     else:
         print("Invalid choice. Try again.")