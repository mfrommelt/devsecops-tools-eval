FROM mcr.microsoft.com/dotnet/sdk:7.0
WORKDIR /app
COPY *.csproj .
RUN dotnet restore
COPY . .
EXPOSE 80
ENV ASPNETCORE_URLS=http://+:80
CMD ["dotnet", "run"]