#include "Program.h"

Program::Program(int w, int h) : width(w), height(h), camera(), eventHandler(camera)

{

}

int Program::mainLoop()

{
	if (!glfwInit())

	{
		std::cout << "GLFW did not init!" << std::endl;
		return EXIT_FAILURE;
	}

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	window = glfwCreateWindow(width, height, "Ray Marching Test", glfwGetPrimaryMonitor(), NULL);
	//glfwGetPrimaryMonitor()

	if (!window)

	{
		std::cout << "Failed to create window!" << std::endl;
		glfwTerminate();
		return EXIT_FAILURE;
	}

	glfwMakeContextCurrent(window);

	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))

	{
		std::cout << "Failed to init GLAD!" << std::endl;
		return EXIT_FAILURE;
	}

	glViewport(0, 0, width, height);
	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
	glfwSetKeyCallback(window, key_callback);
	glfwSetCursorPosCallback(window, cursor_position_callback);
	glfwSetMouseButtonCallback(window, mouse_button_callback);
	glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

	glfwSetWindowUserPointer(window, this);
	glfwSwapInterval(1);
	glClearColor(0.3, 0.8, 0.8, 1.0);

	BasicShader vertexShader(GL_VERTEX_SHADER, "Resources/Shaders/BasicVertex.shader");
	BasicShader fragmentShader(GL_FRAGMENT_SHADER, "Resources/Shaders/BasicFrag.shader");

	unsigned int shaderProgram;
	shaderProgram = glCreateProgram();

	glAttachShader(shaderProgram, vertexShader.getID());
	glAttachShader(shaderProgram, fragmentShader.getID());
	glLinkProgram(shaderProgram);


	//vertexShader.deleteShader();
	//fragmentShader.deleteShader();
	//Temp
	float vertices[] = {
		1.0f, 1.0f, 0.0f,
		1.0f, -1.0f, 0.0f,
		-1.0f, -1.0f, 0.0f,
		-1.0f, 1.0f, 0.0f
	};
	unsigned int indices[] =

	{
		0, 1, 2,
		0, 3, 2
	};
	unsigned int VBO, VAO, EBO;
	glGenVertexArrays(1, &VAO);
	glGenBuffers(1, &VBO);
	glGenBuffers(1, &EBO);
	
	glBindVertexArray(VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
	
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
	
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);

	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
	//


	double ratio = (double)width / (double)height;
	double x = 0.0;
	double y = 0.0;
	double scale = 1.0;
	int stationary = 100;
	float movePenalty = 1.0;
	while (!glfwWindowShouldClose(window))

	{
		camera.update();
		eventHandler.update();
		stationary = stationary < 100 ? 100 : stationary;
		movePenalty = (float)stationary / (float)100;
		x -= camera.vel.x*0.01*scale/movePenalty;
		y += camera.vel.z*0.01*scale/movePenalty;
		if (!eventHandler.locked)
		{
			stationary -= camera.vel.x == 0.0 && camera.vel.y == 0.0 && camera.vel.z == 0.0 ? 0 : 10;
			stationary += 5;
		}
		
		scale -= camera.vel.y * 0.01*scale / movePenalty;

		glClear(GL_COLOR_BUFFER_BIT);

		int rat = glGetUniformLocation(shaderProgram, "ratio");
		glUniform1d(rat, ratio);

		int pos = glGetUniformLocation(shaderProgram, "position");
		glUniform2d(pos, x, y);

		int scal = glGetUniformLocation(shaderProgram, "scale");
		glUniform1d(scal, scale);

		int stat = glGetUniformLocation(shaderProgram, "stationary");
		glUniform1i(stat, stationary);

		//int arrows = glGetUniformLocation(shaderProgram, "arrows");
		//glUniform2f(arrows, eventHandler.arrowRight, eventHandler.arrowUp);

		//int view = glGetUniformLocation(shaderProgram, "cam_rot");
		//glm::mat4 viewMat = makeViewMatrix(camera);
		//glUniformMatrix4fv(view, 1, GL_FALSE, &viewMat[0][0]);

		//int trans = glGetUniformLocation(shaderProgram, "cam_trans");
		//glm::mat4 transMat = makeTransMatrix(camera);
		//glUniformMatrix4fv(trans, 1, GL_FALSE, &transMat[0][0]);

		//std::cout << camera.rot.x << std::endl;

		glUseProgram(shaderProgram);
		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
		//
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
	glfwTerminate();
	return EXIT_SUCCESS;
}

void Program::framebuffer_size_callback(GLFWwindow* window, int w, int h)

{
	glViewport(0, 0, w, h);
	void* ptr = glfwGetWindowUserPointer(window);
	Program *kptr = static_cast<Program*>(ptr);
	kptr->width = w;
	kptr->height = h;
}

void Program::key_callback(GLFWwindow* window, int button, int scancode, int action, int mods)

{
	if (action == GLFW_PRESS && button == GLFW_KEY_ESCAPE) 
		glfwSetWindowShouldClose(window, true);

	void* ptr = glfwGetWindowUserPointer(window);
	Program *kptr = static_cast<Program*>(ptr);
	kptr->eventHandler.keyHandler(action, button);
}

void Program::cursor_position_callback(GLFWwindow* window, double xpos, double ypos)

{
	void* ptr = glfwGetWindowUserPointer(window);
	Program *kptr = static_cast<Program*>(ptr);
	kptr->eventHandler.mouseHandler(xpos, ypos);
}

void Program::mouse_button_callback(GLFWwindow* window, int button, int action, int mods)

{
	void* ptr = glfwGetWindowUserPointer(window);
	Program *kptr = static_cast<Program*>(ptr);
	kptr->eventHandler.mouseButtonHandler(action, button);
}